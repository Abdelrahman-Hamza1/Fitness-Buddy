# A15a — chart feasibility (TD-012), 2026-10-29

**Result: `CustomPainter` for the whole chart, settled by research (A15 plan D2, PA1). No prototype.**

Source: tech-researcher report (Opus, 2026-10-28), with a scratch probe of fl_chart 1.3.0 + material_ui 1.6.0 + alchemist 0.14.1 on the pinned Flutter 3.47.7 and a read of the fl_chart 1.3.0 source.

## What was checked (D2 criteria)

| Criterion | fl_chart 1.3.0 | `CustomPainter` |
|---|---|---|
| (a) points, trend line, dashed projection, cone, goal line, period bands | All possible, but points and the cone need invisible fake bars; no labels on range bands | Ours, all six layers |
| (b) tap to the nearest point with our own hit-test | Possible via `touchChartCoordinate`, but the pixel ↔ data mapping depends on fl_chart's internal title/padding layout | Ours, on the full data |
| (c) controlled visible window for drag-pan | `FlTransformationConfig` matrix semantics, or rebuilding `LineChartData` per frame; **no culling**: every frame walks all spots and rebuilds every `Path` | Transient offset, visible slice by binary search, LTTB |
| (d) time in reading direction under RTL (LC-003) | The plot isn't mirrored; we'd have to mirror it ourselves | x derived from `Directionality` |
| (e) deterministic alchemist goldens | Yes (probe) | Yes (TextPainter text is covered by alchemist's CI variant) |
| (f) material_ui without a bridge | Passes: imports `package:flutter/material.dart` (32 files) but uses only widgets/painting/`Colors`, no `Theme.of` | No Material dependency |
| (h) no library types through the DS API | Needs an adapter | Nothing to leak |

## Why `CustomPainter`
- Once we slice and down-sample the visible window ourselves (D4), fl_chart's remaining value is axis/title layout and a few primitives, roughly 0.3 session of painter code, already in the estimate.
- It ties the DS to the in-framework Material library, which is frozen and slated for removal; fl_chart's material_ui migration issue #2126 has no maintainer reply.
- Maintenance: 1.2.0 (2026-03-13) → 1.3.0 (2026-10-21), a 7-month gap; 390 open issues, one main maintainer.
- Rejected too: graphic 2.7.0 (slowing, extra dependency), community_charts_flutter (last release 2024-05), Syncfusion (commercial licence = new vendor).

## Performance plan (exit 5)
No emulator perf check (emulators have no profile mode). Evidence: the host vertex-cap test and printed benchmark (WP2), Patrol frame timings (WP5), and the owner's A55 over-adb profile pan run (D22), recorded in the A15 card's Progress log. If the A55 run shows jank: cache static layers in a `Picture`.
