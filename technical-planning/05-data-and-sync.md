# 05 — Data Model, Local Storage & Sync

_Logical model. Exact columns are fixed in the migrations of A01/A06 and later steps. This file fixes the **conventions** and **entities**, which are expensive to change later._

## 1. Conventions (every user-data table)

| Convention | Rule | Why |
|---|---|---|
| IDs | **UUIDv7**, generated on the device, stored as text. Natural-key rows (settings, default slots, day marks) use a deterministic **UUIDv5** of `<entity>:<key>` (TD-070) | Created offline without collisions. Time-sortable. Same ID on phone and server |
| Ownership | `user_id` on the server document. Locally, one user per database file | Multi-user from day one (D-001). Simple deletion |
| Sync metadata | `created_at`, `updated_hlc` (hybrid logical clock), `version` (+1 per write), `deleted_at` (tombstone), `device_id` | Last-write-wins sync, deletes that sync, optimistic checks in proposals |
| Units | Canonical: **g / ml** food, **kcal**, **kg** body and lifted weight, **cm** measurements. The **original input** is kept too (`input_amount`, `input_unit`) | Display follows the unit setting (LC-010/011) without rounding drift |
| Time | `occurred_at_utc` + `tz_offset_min` + `local_date` (YYYY-MM-DD) | DY-001/002: entries keep their local day and time across travel |
| Snapshots | Logged items store a **nutrient snapshot** (kcal, P, C, F, fiber + optional extras) and the display name at log time | FD-073: editing a food never rewrites history |
| Provenance | `source` (`yours` / `database` / `reference` / `estimate`), `is_estimate`, `estimate_range`, `assumptions` (JSON), `origin` (direct / proposal ID), `edited_by_user` | SC-4, AI-032/071/072, FD-010 |
| One calculation | Nutrients per 100 g/ml on foods. Entry nutrients = definition × grams / 100, in `fb_domain` with fixed rounding rules | One tested calculation, used by the app and the Dart tools |

## 2. Entities

### 2.1 Food & diary

| Entity | Key fields | Notes |
|---|---|---|
| `personal_foods` | names (en, ar?), aliases[], per-100 nutrients, state, brand, barcodes[], servings[] (name, grams), `created_from` (chat / label / form / saved meal / batch), sanity status | FD-070–073. Private |
| `saved_meals` + `saved_meal_items` | name, items (food ref + snapshot + amount) | DY-031 |
| `diary_entries` | `local_date`, `occurred_at_utc`, `tz_offset_min`, `slot_id`, `dish_group_id?`, `food_ref` (catalog / personal / batch / estimate + ID + catalog version), display name, input amount/unit, grams, nutrient snapshot, provenance, `batch_portion_id?` | Index `(local_date)` |
| `dish_groups` | name, `local_date`, `slot_id` | AI-020, DY-024 |
| `meal_slots` | name, order, time window, `mode` (normal / ramadan), active | DY-010–012 |
| `day_marks` | `local_date`, `incomplete`, `not_fasting` | DY-004, LC-034 |
| `batches` | name, ingredients (food ref, grams, state), totals, `cooked_weight_g?`, `remaining`, status, `auto_close_at` | DY-040–044 |

### 2.2 Body, targets, workouts

| Entity | Key fields |
|---|---|
| `profile` (1 row) | sex, birth_year, height_cm, activity_level, unit system, week_start, halal, city / location mode, language, digit style |
| `goals` (phases) | type, start/end, target weight, rate, monthly target, name |
| `target_settings` (versioned, effective-from date) | base kcal, mode (weekly / fixed), rebalancing, shifting config, protein/fat/fiber rules, manual overrides + acknowledged warning (SF-012), Ramadan variant, check-in mode (ask / auto) |
| `weigh_ins` | measured_at, local_date, kg, input value/unit, note |
| `measurement_types` (custom) + `measurements` | type, value, date |
| `exercises` (custom only; built-ins ship in the catalog pack) | names, aliases, type (WO-004), equipment |
| `workout_templates` + items · `weekly_plan` | name, exercises with target sets×reps · weekday → template |
| `workout_sessions` → `session_exercises` → `sets` | per-set fields depend on exercise type |

PRs, e1RM, trend weight, expenditure and weekly summaries are **derived**, not stored. Weekly reviews are stored because they contain AI text.

### 2.3 Buddy, memory, settings

| Entity | Key fields |
|---|---|
| `chat_messages` | role, text, attachment refs (local paths; **images are not synced**), status (queued / pending_offline / processing / done / failed), language |
| `proposals` | message_id, kind, interpretation (JSON), draft (JSON), status (pending / confirmed / discarded / superseded), outcome (unchanged / adjusted chips / discarded), resolved_at |
| `memory_items` | kind (default / portion / alias / brand / nickname / personal-food link / habit), key, value, `created_from` (explicit / learned), active |
| `answer_log` | question_kind (e.g. `state:rice`), answer, at |
| `weekly_reviews` | week_start, summary snapshot (JSON), narrative, target proposal id |
| `settings_kv` | notification prefs, quiet hours, toggles (key → JSON), synced |

### 2.4 Local-only (never synced)

| Entity | Why |
|---|---|
| `progress_photos` (R2) + files | WB-050: device only, excluded from OS backups (G8) |
| `sync_outbox`, `sync_state` | Sync machinery |
| Offline catalog pack (separate read-only SQLite file) | Shipped by us, not user data |
| Caches (search ranking, quick-add model, user-model aggregates) | Rebuildable from synced data |

## 3. Local database (drift)

- **Two SQLite files:** `user.db` (read/write, migrations) and `catalog.db` (read-only offline pack: basics, reviewed reference dishes, yields, portion words, exercise library, cities). The pack is swapped atomically on update (`07` §6) and attached for cross-queries when needed.
- **FTS5 indexes** (trigram tokenizer) over normalized names. Normalization comes from `fb_text`, so search behaves the same on the phone and the server.
- **Migrations:** drift schema versions with generated **migration tests** from every older version. A shipped migration is never edited.
- **Triggers** on every synced table append to `sync_outbox`, so no code path can forget to sync a change.
- Runs in a **background isolate** (`DriftIsolate.spawn` + `sqlite3.open(uri: true)`, A01 `core/db/connection.dart`; `uri: true` enables the read-only catalog ATTACH) so the UI thread stays free (UX-007).
- **One database per account.** Signing out with "keep a copy" leaves a read-only file. A guest has their own file until they upgrade (§6).

## 4. Server storage

Per TD-031 (`04` §7), the UserData module stores **one JSON document per synced row**: `userdata.documents (user_id, entity, id, schema_version, hlc, device_id, deleted_at, payload, server_seq)`, plus `userdata.row_history` (30 days). Payloads are validated against the entity's JSON schema from the contract.

Other server data: `identity.*` (users, identities, tokens), `catalog.*` (global foods, reference dishes, aliases, yields, `off_cache` kept separate for licensing), `usage.*` (AI counters), `buddy.idempotency`, `account.deletion_requests`, and the outbox and job tables in `ops.*`.

## 5. Sync protocol (custom delta sync, TD-006)

### 5.1 Why custom (and the escape hatch)

Our sync problem is the **easy kind**: every row has exactly one owner, there's no collaboration, conflicts are rare (one person on two phones), and the policy is **row-level last-write-wins + history** (AC-012). A custom protocol keeps full drift features (foreign keys, FTS5 triggers, typed migrations), makes guest mode trivial, and needs no vendor. **B01 confirmed feasibility:** 1,000 fake and 50 real Docker API scenarios, full-version recovery and fault checks pass; see its verification evidence. Production implementation remains B05/A34.

**Escape hatch:** the app talks to a `SyncEngine` interface. If later integration invalidates the spike results, **PowerSync** (self-hostable against our Postgres) replaces the implementation. Repositories and features don't change.

### 5.2 Protocol

```mermaid
sequenceDiagram
  participant C as App (SyncEngine)
  participant S as API (UserData module)
  Note over C: every local write → trigger → sync_outbox
  C->>S: POST /v1/sync/push {changes:[{entity, id, schemaVersion, hlc, deviceId, deletedAt, payload}]}
  S->>S: validate envelope · serialize per user before sequence allocation<br/>per change: validate · LWW upsert and archive displaced version,<br/>or preserve stale incoming version in history
  S-->>C: per-change result (accepted / stale / invalid) + serverTime
  C->>C: delete only acknowledged immutable outbox versions; keep pull cursor
  C->>S: GET /v1/sync/pull?cursor=<last server_seq>&limit=500
  S-->>C: changed documents with server_seq > cursor (any entity), nextCursor
  C->>C: apply each unless a newer local pending change exists (LWW), advance cursor
```

- **Ordering:** a **hybrid logical clock** per device (wall time + counter + device ID), so edits order correctly even with clock skew. B01 bounds future-clock admission at five minutes with `invalid/clockDrift`; the pending version stays local. B05 defines production clock recovery (TD-049). Ties go to the higher device ID.
- **When it runs:** after each local change set (debounced a few seconds), on app foreground, on reconnect, and on pull-to-refresh. **Never on the startup critical path** (UX-001). R2+: an optional "something changed" nudge (SSE or push) for live multi-device updates.
- **Deletes** are tombstones that sync like updates. Tombstones are compacted on the server after 30 days.
- **First sync on a new phone** (AC-011): paged pull from cursor 0. Years of data fit in tens of MB.
- **Idempotent:** pushing the same change twice is harmless (same HLC = no-op).
- **Schema evolution:** documents carry `schemaVersion`. The server stores any version it has a schema for. The app upgrades older documents on pull (upgrader functions in `fb_domain`). Clients that are too old are blocked by the minimum-version gate.
- **Batching & limits:** push ≤ 500 changes per request. Pull pages ≤ 500. Per-user rate limits.
- **Sync indicator** (AC-013): driven by the outbox count + time of the last successful sync.
- **Earlier versions** (G7): item detail → "Earlier versions" calls `GET /v1/sync/history/{entity}/{id}` (online only).
- **Anonymous users** get `403` from sync endpoints (`04` §5).

### 5.3 Sync tests (must pass before A34 ends)

- **Convergence simulation** (property-based, Dart): N simulated devices perform random operations offline, then sync in random orders and interleavings against an in-memory fake of the server rules **and** against the real API (Testcontainers). Assert: every device converges to identical state, no confirmed write is lost without a `row_history` entry, and tombstones win correctly.
- **OF-03** as an end-to-end test against a local API.
- **Fault injection:** network drop mid-push, duplicated responses, server rejects, app killed between push and acknowledgement.
- **Version skew:** an older-schema client syncing with a newer server, and the reverse.

### 5.4 B01 experimental wire handoff (2026-10-16)

This is the protocol A01's outbox should accommodate; the production engine remains A34 and authenticated service B05. The B01 endpoints are unavailable (501) in normal environments. A dedicated `SyncSpike` environment, enabled flag, random test key and configured synthetic user are required by the test harness. Never send real user data to this prototype.

- `POST /v1/sync/push`: `{changes: [{entity,id,schemaVersion,hlc,deviceId,deletedAt,payload}]}`. Required nullable `deletedAt`; object `payload`; prototype allows only `diaryEntry` and `weighIn`, schema 1. 1–500 changes, also constrained by the host's 256 KiB request cap. Split by bytes as well as row count. Each immutable `(entity,id,hlc)` identifies a version. Retrying it is idempotent; a different payload/metadata with that identity is `invalid` (`versionConflict`). Thus this POST is exempt from the generic HTTP idempotency cache. The spike's additional `X-Sync-Spike-Key` is test access only, never the app's authentication protocol.
- Response `{results:[{entity,id,hlc,status,reason}],serverTime}` in input order. `hlc` echoes the submitted version. Status is `accepted`, `stale` or `invalid`; nullable reason is `clockDrift`, `versionConflict` or `unsupported` for invalid changes. Accepted and stale are durably acknowledged; invalid remains in the outbox for intervention/retry. Acknowledging a sent version must not erase a newer concurrent local edit. No sequence in this response may move the pull cursor.
- `GET /v1/sync/pull?cursor=0&limit=100`: `{changes:[{...document,serverSeq}],nextCursor}`. Cursor and sequence are nonnegative decimal **strings** (Postgres bigint), maximum page 500. `nextCursor` is the last **delivered** sequence, or the input cursor when empty. Keep pulling until an empty page. Apply rows and save cursor in one local transaction. Merge by HLC, preserve newer local pending versions, and feed received HLCs to the local clock before further writes. Never set a cursor to the largest sequence in a push acknowledgement or to a global database maximum.
- Pushes serialize **per user before sequence allocation** (`CACHE 1` sequences), within the same transaction as all document/history writes. Global sequence gaps are allowed; same-user commits cannot overtake a previously allocated sequence. Changes concurrent with a pull can move to later pages; duplicate delivery is safe. A fresh device begins at cursor `0`.
- HLC format and binary ordering are exactly TD-049. The HLC device suffix must match `deviceId`. An incoming wall time more than five minutes ahead is `invalid/clockDrift` (response carries server time), keeping the pending row. This bounds admission without changing a version's identity behind the client. B05 decides recovery/re-stamping; TD-049's receive API/default is unchanged.
- The server stores a displaced cross-device version **and a stale incoming cross-device loser** in deduplicated `row_history`. B01 also retains same-device losing versions so immutable version identity can be checked after replacement. A tombstone is an ordinary version, so only a strictly later version can restore it. History has a 30-day recovery horizon; cleanup and resurrection after compaction remain B05 production work.
- Prototype-only `GET /v1/sync/history?cursor=0&limit=100` returns `{changes,nextCursor}` with the same document shape, cursor paging over a separate history sequence. It exists for the harness's independent no-loss assertions, not history UI. A history cursor must never be used as a document pull cursor.

B05 also resolves dataset reset detection (proposed TD-066), schema validation, authentication and production retention. B01 proves convergence within one database dataset; it does not certify reset recovery or a phone network's timing.

## 6. Guest mode & account lifecycle

| Flow | Behaviour |
|---|---|
| First launch | The app works fully offline. In the background (when online) it calls `POST /v1/auth/anonymous` to get an anonymous token for Buddy and search (rate limits). **Sync is off for guests.** Data stays on the device (AC-002) |
| Sign up from guest (AC-003) | `POST /v1/auth/link/{provider}` links the identity to the **same user ID**. Then sync turns on and every local row is enqueued and pushed |
| Sign in on a device with guest data, to an **existing** account | Ask: merge this device's guest data into the account, or discard it. Merge = re-own the rows and push them (UUIDs avoid collisions) |
| Sign out (AC-004) | Ask: keep the local copy (read-only until sign-in) or wipe it. Wipe deletes `user.db` and secure storage |
| Export (AC-030) | **Generated on the device** from `user.db`: CSV per type + one JSON file. Works offline and for guests. Shared through the OS share sheet |
| Delete account (AC-031) | Explain → confirm → `DELETE /v1/me` → the Account module deletes all user documents, history and identities **immediately** (via integration events to each module), revokes tokens, then wipes the device. Backups age out within 30 days (`08` §5) |

## 7. Data retention summary (for the privacy policy, AC-044 R3)

| Data | Where | Retention |
|---|---|---|
| User data | Phone + our Postgres (Germany) | Until the user deletes it or the account |
| Overwritten versions | `userdata.row_history` | 30 days |
| Database backups | Object storage (Germany + a second EU provider) | 30 days |
| Buddy request content | API memory only. AI provider abuse logs (provider policy, TQ-06) | Not stored by us |
| Buddy and label photos | Sent once through the API to the AI provider. Not stored on our servers. The local copy stays with the chat message | — |
| Progress photos (R2) | Device only | User controlled |
| Logs, traces, errors | Grafana Cloud, Sentry (no user content, IDs only) | 30–90 days |
