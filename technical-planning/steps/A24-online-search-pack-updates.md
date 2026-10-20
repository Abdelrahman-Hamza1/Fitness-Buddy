# A24 — Online search & pack updates (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A07, **B07** | M | Codex (TD-078) | ⬜ Not started |

_Old ID: S30 app part (renumbered by TD-063, 2026-10-16). The server side is B07._

**Goal.** Search finds everything the server catalog has when online, without ever slowing the local results, and the offline pack updates itself safely in the background.

**Spec:** FD-020 (online full search), FD-021, FD-023 (pack updates) · **Decisions:** TD-005, TD-010

## Scope
- **Online search merged with local results:** local results first, online results appended when they arrive, de-duplicated by catalog ID (`07` §5.2). Offline: local only, no error state.
- **Pack update** in the background (`07` §6): `GET /v1/catalog/packs/latest` → download → verify checksum → atomic swap → reattach `catalog.db`. Never on the startup path; a failed or partial download leaves the current pack in use.

## Out of scope
- The server catalog and pack publishing (B07). Barcode lookups (A28).

## Exit criteria
- [ ] The app merges online + offline results without duplicates (integration test).
- [ ] Pack update E2E against the laptop server: publish a new release → the app picks it up on next launch, verifies it, swaps it, and diary entries are unaffected.
- [ ] A corrupted download is rejected and the old pack stays (test).

## Read first
`07-food-data.md` §5–6 · `05-data-and-sync.md` §3 · A05, B07 Outcomes

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
