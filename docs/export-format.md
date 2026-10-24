# Fitness Buddy export format v1

Exports are built offline on this phone, for guests and signed-in users. There is no import feature.
Only live rows are exported. Tombstones, `device_id` (install identity), and `updated_hlc`
(which embeds install identity) never appear. Catalog packs, sync state/outbox, sessions and
credentials are not user entities and are not exported. Names referenced from a deleted or
inactive parent are still resolved; an absent parent produces null (empty CSV).

Each export produces eight CSVs and one complete JSON file, named
`fitness-buddy-YYYY-MM-DD-<type>.csv` and `fitness-buddy-YYYY-MM-DD.json` using the local
export date. Rows sort by id, except diary entries sort by local_date, occurred_at_utc, id.
Files are in app-private temporary `export/`, wiped at the start of the next export.
Sharing uses the OS share sheet. share_plus 13.3.1 also copies files into `cache/share_plus/`,
which remains until the next share; our export-directory wipe does not remove that copy.
Recipients and chosen share targets can retain their own copies. Exports contain private diary data.

CSV is UTF-8 with BOM, RFC 4180 quoting (quotes doubled), CRLF records, one header row,
null as empty, booleans `true`/`false`, and decimal point `.` with no grouping. Doubles use
shortest round-trip text, dropping `.0` for whole values. Text beginning with `=`, `+`, `-`,
`@`, tab or CR is prefixed with a single quote to prevent spreadsheet formula execution.
Numeric negative values are unchanged. This quote is CSV-only; JSON retains exact text.
JSON columns remain stored JSON text inside CSV cells (subject to CSV quoting).

The JSON object is:
```json
{"format":"fitness-buddy-export","formatVersion":1,"exportedAt":"2026-10-24T12:00:00.000Z","app":{"version":"0.1.0","build":"1"},"schemaVersion":4,"counts":{"diaryEntry":0},"data":{"diaryEntry":[]}}
```
`schemaVersion` comes from the open database, not a format constant. `counts` and `data`
contain every entity listed below, including empty arrays. Numbers and booleans retain types,
null stays null, and each `*_json` field is parsed as a nested JSON value under the same key.
`occurred_at_utc` is integer UTC milliseconds; `created_at` is UTC ISO-8601 text in both formats.
`version` and `origin` are JSON-only; every other listed column appears in both formats.
`formatVersion` changes only for a rename, removal or meaning change. New files/columns
are additive; readers must ignore unknown ones.

Column paths below use `<type>.<column>` (the date prefix and `.csv` omitted).
All text is exact stored content unless explicitly marked derived. Nutrients are snapshots,
never recomputed during export. Per-100 nutrients are per 100 g or ml according to basis;
energy is kcal, macros/fiber are grams. All ids are opaque row identifiers.

## diary-entries (`diaryEntry`, `diary_entries`)

| Column | Type / unit | Meaning |
|---|---|---|
| `diary-entries.id` | text | UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys (`core/db/natural_id.dart`). Lowercase canonical text. |
| `diary-entries.food_kind` | text | `catalog`, `personal`, `estimate` (A27 adds `batch`). |
| `diary-entries.food_id` | text | The food's opaque id, `null` for an estimate. |
| `diary-entries.food_version` | text | The catalog pack version at log time (opaque), or `null`. |
| `diary-entries.name_en` | text | The English name. User or catalog content. |
| `diary-entries.name_ar` | text | The Arabic name, when there is one. |
| `diary-entries.input_amount` | number | The amount as typed. |
| `diary-entries.input_unit` | text | The unit as typed. |
| `diary-entries.amount` | number | The canonical amount, grams or ml. |
| `diary-entries.amount_basis` | text | `g` or `ml`. |
| `diary-entries.per100_kcal` | number | Per-100 kcal. |
| `diary-entries.per100_protein_g` | number | Per-100 protein, g. |
| `diary-entries.per100_carbs_g` | number | Per-100 carbs, g. |
| `diary-entries.per100_fat_g` | number | Per-100 fat, g. |
| `diary-entries.per100_fiber_g` | number | Per-100 fiber, g. |
| `diary-entries.per100_extras_json` | JSON value | Per-100 extras as JSON (`{"sugar": 1.2}`), or `null`. |
| `diary-entries.kcal` | number | The snapshot kcal for [amount]. |
| `diary-entries.protein_g` | number | The snapshot protein, g. |
| `diary-entries.carbs_g` | number | The snapshot carbs, g. |
| `diary-entries.fat_g` | number | The snapshot fat, g. |
| `diary-entries.fiber_g` | number | The snapshot fiber, g. |
| `diary-entries.extras_json` | JSON value | The snapshot extras as JSON, or `null`. |
| `diary-entries.source` | text | The badge: `yours`, `database`, `reference`, `estimate`. |
| `diary-entries.is_estimate` | boolean | Whether the values are estimated. |
| `diary-entries.estimate_range_json` | JSON value | `{"lowKcal": …, "highKcal": …}` for an estimate with a range. |
| `diary-entries.assumptions_json` | JSON value | The assumptions behind the values, a JSON list of strings. |
| `diary-entries.local_date` | text | The day, `YYYY-MM-DD`. |
| `diary-entries.occurred_at_utc` | UTC ms | When it was eaten, UTC ms. |
| `diary-entries.tz_offset_min` | integer | The zone offset where it was eaten, minutes ahead of UTC. |
| `diary-entries.slot_id` | text | The meal slot's id. |
| `diary-entries.dish_group_id` | text | The dish group's id, or `null`. |
| `diary-entries.occurred_at` | derived text | Derived local ISO-8601 time with numeric offset from occurred_at_utc + tz_offset_min. |
| `diary-entries.meal` | derived text | Derived slot name, falling back to default_key, including deleted/inactive slots. |
| `diary-entries.created_at` | UTC ISO-8601 | Creation time, UTC ISO-8601 text (seed rows use the epoch). |
| `diary-entries.edited_by_user` | boolean | Provenance: the user overrode a value that came from another source (AI-072, the "edited by you" badge). Set only by ops. |
| `diary-entries.version` | integer | 1 on insert, +1 per write: the local optimistic concurrency check. JSON only. |
| `diary-entries.origin` | text | `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`. JSON only. |

## dish-groups (`dishGroup`, `dish_groups`)

| Column | Type / unit | Meaning |
|---|---|---|
| `dish-groups.id` | text | UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys (`core/db/natural_id.dart`). Lowercase canonical text. |
| `dish-groups.name` | text | The meal's name. User content. |
| `dish-groups.local_date` | text | The day, `YYYY-MM-DD`. |
| `dish-groups.slot_id` | text | The meal slot's id. |
| `dish-groups.created_at` | UTC ISO-8601 | Creation time, UTC ISO-8601 text (seed rows use the epoch). |
| `dish-groups.edited_by_user` | boolean | Provenance: the user overrode a value that came from another source (AI-072, the "edited by you" badge). Set only by ops. |
| `dish-groups.version` | integer | 1 on insert, +1 per write: the local optimistic concurrency check. JSON only. |
| `dish-groups.origin` | text | `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`. JSON only. |

## day-marks (`dayMark`, `day_marks`)

| Column | Type / unit | Meaning |
|---|---|---|
| `day-marks.id` | text | UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys (`core/db/natural_id.dart`). Lowercase canonical text. |
| `day-marks.local_date` | text | The day, `YYYY-MM-DD`. |
| `day-marks.incomplete` | boolean | Whether the day is marked incomplete. |
| `day-marks.not_fasting` | boolean | Whether a Ramadan day is marked not fasting (A41). |
| `day-marks.created_at` | UTC ISO-8601 | Creation time, UTC ISO-8601 text (seed rows use the epoch). |
| `day-marks.edited_by_user` | boolean | Provenance: the user overrode a value that came from another source (AI-072, the "edited by you" badge). Set only by ops. |
| `day-marks.version` | integer | 1 on insert, +1 per write: the local optimistic concurrency check. JSON only. |
| `day-marks.origin` | text | `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`. JSON only. |

## meal-slots (`mealSlot`, `meal_slots`)

| Column | Type / unit | Meaning |
|---|---|---|
| `meal-slots.id` | text | UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys (`core/db/natural_id.dart`). Lowercase canonical text. |
| `meal-slots.default_key` | text | `breakfast` … for a default slot, `null` for a custom one. |
| `meal-slots.name` | text | The meal's name. User content. |
| `meal-slots.sort_order` | integer | The position in the meal. |
| `meal-slots.window_start_min` | integer | The window start, minutes after local midnight (0-1439), or `null`. |
| `meal-slots.window_end_min` | integer | The window end (exclusive), or `null`. Both bounds or neither. |
| `meal-slots.mode` | text | `normal` or `ramadan`. |
| `meal-slots.active` | boolean | Whether the slot is in use. |
| `meal-slots.created_at` | UTC ISO-8601 | Creation time, UTC ISO-8601 text (seed rows use the epoch). |
| `meal-slots.edited_by_user` | boolean | Provenance: the user overrode a value that came from another source (AI-072, the "edited by you" badge). Set only by ops. |
| `meal-slots.version` | integer | 1 on insert, +1 per write: the local optimistic concurrency check. JSON only. |
| `meal-slots.origin` | text | `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`. JSON only. |

## personal-foods (`personalFood`, `personal_foods`)

| Column | Type / unit | Meaning |
|---|---|---|
| `personal-foods.id` | text | UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys (`core/db/natural_id.dart`). Lowercase canonical text. |
| `personal-foods.name_en` | text | The English name. User or catalog content. |
| `personal-foods.name_ar` | text | The Arabic name, when there is one. |
| `personal-foods.aliases_json` | JSON value | Optional JSON alias list. |
| `personal-foods.brand` | text | Optional brand. |
| `personal-foods.barcodes_json` | JSON value | Optional JSON GTIN list. |
| `personal-foods.per100_extras_json` | JSON value | Per-100 extras as JSON (`{"sugar": 1.2}`), or `null`. |
| `personal-foods.servings_json` | JSON value | Optional JSON serving definitions. |
| `personal-foods.entry_serving_unit` | text | Original entry serving code. |
| `personal-foods.created_from` | text | Creation method, open for later steps. |
| `personal-foods.state` | text | Nutrient state code. |
| `personal-foods.basis` | text | Grams or ml. |
| `personal-foods.per100_kcal` | number | Per-100 kcal. |
| `personal-foods.per100_protein_g` | number | Per-100 protein, g. |
| `personal-foods.per100_carbs_g` | number | Per-100 carbs, g. |
| `personal-foods.per100_fat_g` | number | Per-100 fat, g. |
| `personal-foods.per100_fiber_g` | number | Per-100 fiber, g. |
| `personal-foods.entry_serving_amount` | number | Original entry serving amount on this basis. |
| `personal-foods.created_at` | UTC ISO-8601 | Creation time, UTC ISO-8601 text (seed rows use the epoch). |
| `personal-foods.edited_by_user` | boolean | Provenance: the user overrode a value that came from another source (AI-072, the "edited by you" badge). Set only by ops. |
| `personal-foods.version` | integer | 1 on insert, +1 per write: the local optimistic concurrency check. JSON only. |
| `personal-foods.origin` | text | `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`. JSON only. |

## saved-meals (`savedMeal`, `saved_meals`)

| Column | Type / unit | Meaning |
|---|---|---|
| `saved-meals.id` | text | UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys (`core/db/natural_id.dart`). Lowercase canonical text. |
| `saved-meals.name` | text | The meal's name. User content. |
| `saved-meals.created_at` | UTC ISO-8601 | Creation time, UTC ISO-8601 text (seed rows use the epoch). |
| `saved-meals.edited_by_user` | boolean | Provenance: the user overrode a value that came from another source (AI-072, the "edited by you" badge). Set only by ops. |
| `saved-meals.version` | integer | 1 on insert, +1 per write: the local optimistic concurrency check. JSON only. |
| `saved-meals.origin` | text | `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`. JSON only. |

## saved-meal-items (`savedMealItem`, `saved_meal_items`)

| Column | Type / unit | Meaning |
|---|---|---|
| `saved-meal-items.id` | text | UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys (`core/db/natural_id.dart`). Lowercase canonical text. |
| `saved-meal-items.food_kind` | text | `catalog`, `personal`, `estimate` (A27 adds `batch`). |
| `saved-meal-items.food_id` | text | The food's opaque id, `null` for an estimate. |
| `saved-meal-items.food_version` | text | The catalog pack version at log time (opaque), or `null`. |
| `saved-meal-items.name_en` | text | The English name. User or catalog content. |
| `saved-meal-items.name_ar` | text | The Arabic name, when there is one. |
| `saved-meal-items.input_amount` | number | The amount as typed. |
| `saved-meal-items.input_unit` | text | The unit as typed. |
| `saved-meal-items.amount` | number | The canonical amount, grams or ml. |
| `saved-meal-items.amount_basis` | text | `g` or `ml`. |
| `saved-meal-items.per100_kcal` | number | Per-100 kcal. |
| `saved-meal-items.per100_protein_g` | number | Per-100 protein, g. |
| `saved-meal-items.per100_carbs_g` | number | Per-100 carbs, g. |
| `saved-meal-items.per100_fat_g` | number | Per-100 fat, g. |
| `saved-meal-items.per100_fiber_g` | number | Per-100 fiber, g. |
| `saved-meal-items.per100_extras_json` | JSON value | Per-100 extras as JSON (`{"sugar": 1.2}`), or `null`. |
| `saved-meal-items.kcal` | number | The snapshot kcal for [amount]. |
| `saved-meal-items.protein_g` | number | The snapshot protein, g. |
| `saved-meal-items.carbs_g` | number | The snapshot carbs, g. |
| `saved-meal-items.fat_g` | number | The snapshot fat, g. |
| `saved-meal-items.fiber_g` | number | The snapshot fiber, g. |
| `saved-meal-items.extras_json` | JSON value | The snapshot extras as JSON, or `null`. |
| `saved-meal-items.source` | text | The badge: `yours`, `database`, `reference`, `estimate`. |
| `saved-meal-items.is_estimate` | boolean | Whether the values are estimated. |
| `saved-meal-items.estimate_range_json` | JSON value | `{"lowKcal": …, "highKcal": …}` for an estimate with a range. |
| `saved-meal-items.assumptions_json` | JSON value | The assumptions behind the values, a JSON list of strings. |
| `saved-meal-items.saved_meal_id` | text | The saved meal's id. |
| `saved-meal-items.sort_order` | integer | The position in the meal. |
| `saved-meal-items.saved_meal_name` | derived text | Derived parent meal name, including deleted meals. |
| `saved-meal-items.created_at` | UTC ISO-8601 | Creation time, UTC ISO-8601 text (seed rows use the epoch). |
| `saved-meal-items.edited_by_user` | boolean | Provenance: the user overrode a value that came from another source (AI-072, the "edited by you" badge). Set only by ops. |
| `saved-meal-items.version` | integer | 1 on insert, +1 per write: the local optimistic concurrency check. JSON only. |
| `saved-meal-items.origin` | text | `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`. JSON only. |

## settings (`setting`, `settings_kv`)

| Column | Type / unit | Meaning |
|---|---|---|
| `settings.id` | text | UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys (`core/db/natural_id.dart`). Lowercase canonical text. |
| `settings.value_json` | JSON value | The value as JSON text. |
| `settings.key` | derived text | Derived setting name: reverse lookup of naturalId('setting', name) over AppSettings.all; unknown ids use empty text. |
| `settings.created_at` | UTC ISO-8601 | Creation time, UTC ISO-8601 text (seed rows use the epoch). |
| `settings.edited_by_user` | boolean | Provenance: the user overrode a value that came from another source (AI-072, the "edited by you" badge). Set only by ops. |
| `settings.version` | integer | 1 on insert, +1 per write: the local optimistic concurrency check. JSON only. |
| `settings.origin` | text | `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`. JSON only. |

