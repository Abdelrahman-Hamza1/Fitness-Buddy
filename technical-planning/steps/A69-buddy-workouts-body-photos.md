# A69 — Buddy workouts, body data, photos, labels & imports (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A66, **B26** | L | Claude (Opus build), Codex review | ⬜ |

**Goal.** The remaining Buddy inputs: workouts by chat (WO-030–033, AI-053), measurements and weigh-ins with trend (AI-052, WB-040), paste import review (AI-057, WB-030–032), meal photos (AI-011) and label scans (AI-012, FD-040–042). Replaces A28b, A29 and A37b.

## Scope
1. `workout` card (exercises, sets, per-dumbbell semantics, PR hints, "same as last push") → the A37 workout write path.
2. `measurement` card; `importRows` review table (unit inference "110k" → kg flagged, implausible jumps, duplicates).
3. Photo attach in the Buddy bar (camera/gallery, JPEG ≤ 1024 px) for meal photos; estimate badges forced unless grams are stated.
4. Label scan: from the barcode "not found" path and the personal-food form, `POST /v1/buddy/label` → review screen with highlighted uncertain fields and the FD-012 sanity check → personal food linked to the barcode.
5. **Tests (TD-128):** the confirmation guard for each new card kind.

## Exit criteria
1. On the A55: "push day bench 3x8 80, incline db 3x10 24" → workout card → saved session; a pasted weight list → review table → imported; a meal photo → estimated card; a label photo → reviewed personal food.
2. CI green; Codex review passed.

## Lane
Lane 2 after A67, or lane 1 after A68.

## Progress log

## Outcome
