# A01 — Local data foundation

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | S06 ✅, S08 ✅ | M | Claude | ⬜ Not started |

_Old ID: S09 (renumbered by TD-063, 2026-10-16)._

**Goal.** The app's local database and its single write path: drift with migration tests, sync metadata on every table, outbox triggers, and the `ChangeSetApplier` with undo and domain events. Every feature that stores data uses exactly this.

**Spec:** AI-048, UX-030 (direct action + undo mechanism), AI-036 (proposals never applied implicitly, mechanism), AC-012 (sync metadata), D-079 · **Decisions:** TD-005, TD-011, TD-017

## Scope
- **drift setup:** `user.db` (read/write) in a background isolate. A `catalog.db` attach point (the pack arrives in A05). **One database file per account/guest** (`05` §3).
- **Conventions as code:** a table mixin for sync metadata (`id` UUIDv7, `created_at`, `updated_hlc`, `version`, `deleted_at`, `device_id`, `origin`, `edited_by_user`). A generator or helper so every synced table gets its **outbox trigger** automatically.
- **Migration harness:** schema dumps per version + generated migration tests from every older version. A rule (and CI check) that shipped migrations are never edited.
- **`ChangeOp` / `ChangeSet`** (sealed, freezed). The **`ChangeSetApplier`**: one transaction, precondition checks (`expectedVersion`), applies ops, bumps `version`/`updated_hlc`, writes the outbox (via triggers), records `origin`, returns the **inverse** change set, emits **domain events**.
- **`UndoStack`** + the hook used by the design system's undo snackbar (5 s, UX-030).
- **`DomainEventBus`** (typed events, synchronous after commit).
- **Repositories:** read streams (`watch()`) + a **library-private write API** only the applier can call. An **architecture test** fails if anything else imports the write API.
- `settings_kv` table + a settings store (first real use of the stack), and `sync_state` / `sync_outbox` tables (used by B01/A34).

## Out of scope
- Diary/food tables (A06+). Sync transport (B01/A34).

## Fixed by the plan
- The single-writer pattern and its guarantees (`03` §5). Tombstones for deletes. HLC from S08.

## Decide in the low-level plan
- How ops are expressed for generic CRUD vs entity-specific ops (balance type safety vs boilerplate).
- Inverse computation strategy (snapshot before write vs per-op inverse).
- How domain events are delivered to Riverpod (stream vs callbacks).

## Notes from earlier steps
- **From S08:** HLC columns use binary collation (SQLite default `BINARY`; TD-049). Use `fb_domain`'s `Clock`/`IdGenerator`; the app wires `lib/system.dart` (not exported from the barrel). `EntryTime` stores `occurredAtUtc` + `tzOffsetMin`.

## Exit criteria
- [ ] A change set with several ops applies atomically. A failure in one op rolls everything back (test).
- [ ] Undo restores the exact previous state, including tombstoned rows (test).
- [ ] An `expectedVersion` mismatch is rejected with a typed failure (test).
- [ ] Every synced table write produces an outbox row (trigger test). Writes outside the applier fail the architecture test.
- [ ] The migration harness is green with at least two schema versions.
- [ ] Applying a 10-op change set takes < 10 ms on the A55 (measured).

## Read first
`03-architecture.md` §4–5 · `05-data-and-sync.md` §1–3

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
