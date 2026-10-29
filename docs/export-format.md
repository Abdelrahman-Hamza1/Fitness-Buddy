# Fitness Buddy export format v1

Exports are built offline on this phone, for guests and signed-in users. There is no import feature.
Only live rows are exported. Tombstones, `device_id` (install identity), and `updated_hlc`
(which embeds install identity) never appear. Catalog packs, sync state/outbox, sessions and
credentials are not user entities and are not exported. Names referenced from a deleted or
inactive parent are still resolved; an absent parent produces null (empty CSV).

Android backups are separate from this shareable format: they contain the raw
DB, including historical install IDs and sync bookkeeping (outbox and HLC state),
as approved for encrypted device transfer/E2EE cloud backup (A11 Q2). Active
install-id preferences and credentials are excluded. A new install uses a fresh
active ID while preserving historical row/outbox identities.

Each export produces twelve CSVs and one complete JSON file, named
`fitness-buddy-YYYY-MM-DD-<type>.csv` and `fitness-buddy-YYYY-MM-DD.json` using the local
export date. Rows sort by id, except diary entries sort by local_date, occurred_at_utc, id
and weigh-ins by local_date, measured_at_utc, id.
Files are in app-private temporary `export/`, wiped before preparation and after
share returns (also after failure or abandonment). Closing during preparation skips
sharing. Sharing uses the OS share sheet. share_plus 13.3.1 copies files into
`cache/share_plus/`; these unencrypted handoff copies remain readable after the
chooser returns so receiving apps can read their content URIs. A best-effort sweep
removes only regular files older than 24 hours at the next export and on app start
after the first frame. Each sweep visits at most 256 entries and has a two-second
time budget; failures are swallowed without logging paths or content. This is an
age threshold, not a guaranteed deletion deadline: copies can remain longer if
the app is not reopened, the budget is exhausted or storage cleanup fails.
share_plus also clears its own cache on the next share; complete receipt before
starting another export.
Android handoff does not prove delivery: an unavailable result may also mean dismissal.
Recipients and chosen share targets can retain their own copies. Exports contain private diary data.

CSV is UTF-8 with BOM, RFC 4180 quoting (quotes doubled), CRLF records, one header row,
null as empty, booleans `true`/`false`, and decimal point `.` with no grouping. Doubles use
shortest round-trip text, dropping `.0` for whole values. Text whose first effective character after whitespace, controls, BOM or zero-width
characters is `=`, `+`, `-`, or `@` (or legacy leading tab/CR text) is prefixed with a single quote to prevent spreadsheet formula execution.
Numeric negative values are unchanged. This quote is CSV-only; JSON retains exact text.
JSON columns remain stored JSON text inside CSV cells (subject to CSV quoting).

The JSON object is:
```json
{"format":"fitness-buddy-export","formatVersion":1,"exportedAt":"2026-10-24T12:00:00.000Z","app":{"version":"0.1.0","build":"1"},"schemaVersion":4,"counts":{"diaryEntry":0},"data":{"diaryEntry":[]}}
```
`schemaVersion` comes from the open database, not a format constant. `counts` and `data`
contain every entity listed below, including empty arrays. Numbers and booleans retain types,
null stays null, and each `*_json` field is parsed as a nested JSON value under the same key.
`occurred_at_utc` and `measured_at_utc` are integer UTC milliseconds; `created_at` is UTC ISO-8601 text in both formats.
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

## goal-phases (`goalPhase`, `goal_phases`)

| Column | Type / unit | Meaning |
|---|---|---|
| `goal-phases.id` | text | UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys (`core/db/natural_id.dart`). Lowercase canonical text. |
| `goal-phases.revision` | integer | The goal or settings revision (1, 2, …), separate from `version`. |
| `goal-phases.name` | text | The goal's name, or null for the default label. User content. |
| `goal-phases.start_date` | text | The first day, `YYYY-MM-DD`. |
| `goal-phases.end_date` | text | The last day, `YYYY-MM-DD`, or null while the goal is open. |
| `goal-phases.goal_type` | text | `lose`, `maintain` or `gain`. |
| `goal-phases.expression_kind` | text | How the goal is set: `targetDate`, `targetRate`, `weekly` or `monthly` (maintain is `weekly` 0). |
| `goal-phases.target_kg` | number | Target weight, kg (`targetDate`, `targetRate`). |
| `goal-phases.target_date` | text | Target date, `YYYY-MM-DD` (`targetDate`). |
| `goal-phases.kg_per_week` | number | kg a week: a positive speed (`targetRate`) or signed, negative for loss (`weekly`). |
| `goal-phases.month_kg` | number | Signed kg over the named month (`monthly`). |
| `goal-phases.month` | text | The named month's first day, `YYYY-MM-DD` (`monthly`). |
| `goal-phases.weight_input_unit` | text | The unit the goal was typed in: `kg` or `lb` (values above are kg). |
| `goal-phases.created_at` | UTC ISO-8601 | Creation time, UTC ISO-8601 text (seed rows use the epoch). |
| `goal-phases.edited_by_user` | boolean | Provenance: the user overrode a value that came from another source (AI-072, the "edited by you" badge). Set only by ops. |
| `goal-phases.version` | integer | 1 on insert, +1 per write: the local optimistic concurrency check. JSON only. |
| `goal-phases.origin` | text | `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`. JSON only. |

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

## profile (`profile`, `profile`)

| Column | Type / unit | Meaning |
|---|---|---|
| `profile.id` | text | UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys (`core/db/natural_id.dart`). Lowercase canonical text. |
| `profile.sex` | text | `male` or `female`, for the energy formula. |
| `profile.birth_year` | integer | Birth year. |
| `profile.height_cm` | number | Height, cm. |
| `profile.height_input_unit` | text | How the height was typed: `cm` or `ft_in`. |
| `profile.activity` | text | `sedentary`, `light`, `moderate` or `high`. |
| `profile.created_at` | UTC ISO-8601 | Creation time, UTC ISO-8601 text (seed rows use the epoch). |
| `profile.edited_by_user` | boolean | Provenance: the user overrode a value that came from another source (AI-072, the "edited by you" badge). Set only by ops. |
| `profile.version` | integer | 1 on insert, +1 per write: the local optimistic concurrency check. JSON only. |
| `profile.origin` | text | `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`. JSON only. |

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

## target-settings (`targetSettings`, `target_settings`)

| Column | Type / unit | Meaning |
|---|---|---|
| `target-settings.id` | text | UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys (`core/db/natural_id.dart`). Lowercase canonical text. |
| `target-settings.revision` | integer | The goal or settings revision (1, 2, …), separate from `version`. |
| `target-settings.effective_from` | text | The first day this targets version applies, `YYYY-MM-DD`. |
| `target-settings.mode` | text | `weekly` (weekly budget) or `fixed` (same every day). |
| `target-settings.rebalancing` | boolean | Whether earlier days rebalance the rest of the week. |
| `target-settings.base_kcal` | number | The daily base target, kcal (calculated or set by the user). Daily targets are derived. |
| `target-settings.manual` | boolean | Whether the base is the user's own target. |
| `target-settings.acknowledged` | boolean | Whether the user acknowledged a manual target below the safety limits. |
| `target-settings.basis_weight_kg` | number | The body weight the base was calculated with, kg. |
| `target-settings.shift_mon` | number | Monday's higher-calorie weight, or null for 1.0. |
| `target-settings.shift_tue` | number | Tuesday's higher-calorie weight, or null for 1.0. |
| `target-settings.shift_wed` | number | Wednesday's higher-calorie weight, or null for 1.0. |
| `target-settings.shift_thu` | number | Thursday's higher-calorie weight, or null for 1.0. |
| `target-settings.shift_fri` | number | Friday's higher-calorie weight, or null for 1.0. |
| `target-settings.shift_sat` | number | Saturday's higher-calorie weight, or null for 1.0. |
| `target-settings.shift_sun` | number | Sunday's higher-calorie weight, or null for 1.0. |
| `target-settings.protein_value` | number | Protein override (grams, or percent of base energy), or null for the default. |
| `target-settings.protein_is_percent` | boolean | Whether `protein_value` is a percent. |
| `target-settings.fat_value` | number | Fat override (grams, or percent of base energy), or null for the default. |
| `target-settings.fat_is_percent` | boolean | Whether `fat_value` is a percent. |
| `target-settings.carbs_value` | number | Carbs override (grams, or percent of base energy), or null for the default. |
| `target-settings.carbs_is_percent` | boolean | Whether `carbs_value` is a percent. |
| `target-settings.fiber_g` | number | Daily fiber target, g, or null for the default. |
| `target-settings.calories_protein_only` | boolean | Whether only calories and protein have targets. |
| `target-settings.created_at` | UTC ISO-8601 | Creation time, UTC ISO-8601 text (seed rows use the epoch). |
| `target-settings.edited_by_user` | boolean | Provenance: the user overrode a value that came from another source (AI-072, the "edited by you" badge). Set only by ops. |
| `target-settings.version` | integer | 1 on insert, +1 per write: the local optimistic concurrency check. JSON only. |
| `target-settings.origin` | text | `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`. JSON only. |

## weigh-ins (`weighIn`, `weigh_ins`)

| Column | Type / unit | Meaning |
|---|---|---|
| `weigh-ins.id` | text | UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys (`core/db/natural_id.dart`). Lowercase canonical text. |
| `weigh-ins.local_date` | text | The day, `YYYY-MM-DD`, from the offset where it was measured. |
| `weigh-ins.measured_at_utc` | UTC ms | When it was measured, UTC ms. |
| `weigh-ins.tz_offset_min` | integer | The zone offset where it was measured, minutes ahead of UTC. |
| `weigh-ins.kg` | number | The weight in kg, rounded once to 2 decimals from the typed value. |
| `weigh-ins.input_value` | number | The value as typed. |
| `weigh-ins.input_unit` | text | The unit as typed: `kg` or `lb`. |
| `weigh-ins.note` | text | The optional note. User content. |
| `weigh-ins.preferred_for_day` | boolean | The user picked this weigh-in for the trend on its day (otherwise the day's earliest is used). The trend itself is derived and not exported. |
| `weigh-ins.created_at` | UTC ISO-8601 | Creation time, UTC ISO-8601 text (seed rows use the epoch). |
| `weigh-ins.edited_by_user` | boolean | Provenance: the user overrode a value that came from another source (AI-072, the "edited by you" badge). Set only by ops. |
| `weigh-ins.version` | integer | 1 on insert, +1 per write: the local optimistic concurrency check. JSON only. |
| `weigh-ins.origin` | text | `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`. JSON only. |
