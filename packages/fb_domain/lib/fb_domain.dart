/// Pure Dart domain models, business rules and algorithms for Fitness Buddy.
///
/// No Flutter, no I/O, no `DateTime.now()` or `Random`: time and IDs are
/// injected by the caller. The production sources are in
/// `package:fb_domain/system.dart` and the test fakes in
/// `package:fb_domain/testing.dart`, which this barrel doesn't export.
library;

export 'src/account/guest_prompt_policy.dart';
export 'src/body/measurement.dart';
export 'src/body/measurement_ops.dart';
export 'src/body/measurement_series.dart';
export 'src/body/smooth_daily.dart';
export 'src/body/trend_weight.dart';
export 'src/body/weigh_in.dart';
export 'src/body/weigh_in_batch.dart';
export 'src/body/weigh_in_cadence.dart';
export 'src/body/weigh_in_check.dart';
export 'src/body/weigh_in_ops.dart';
export 'src/body/weight_graph.dart';
export 'src/changes/change_op.dart';
export 'src/changes/domain_event.dart';
export 'src/changes/origin.dart';
export 'src/chat/chat_language.dart';
export 'src/chat/chat_message.dart';
export 'src/chat/chat_message_ops.dart';
export 'src/chat/chat_text.dart';
export 'src/diary/day_layout.dart';
export 'src/diary/diary_entry.dart';
export 'src/diary/diary_events.dart';
export 'src/diary/diary_ops.dart';
export 'src/diary/entry_measures.dart';
export 'src/diary/food_history.dart';
export 'src/diary/food_ref.dart';
export 'src/diary/meal_slot.dart';
export 'src/diary/meal_slot_ops.dart';
export 'src/diary/meal_slot_rules.dart';
export 'src/diary/provenance.dart';
export 'src/diary/saved_meal.dart';
export 'src/diary/slot_assigner.dart';
export 'src/diary/totals.dart';
export 'src/food/food_state.dart';
export 'src/food/gtin.dart';
export 'src/food/halal_check.dart';
export 'src/food/off_origin.dart';
export 'src/food/personal_food.dart';
export 'src/food/personal_food_merge.dart';
export 'src/food/personal_food_ops.dart';
export 'src/food/portion/default_portion.dart';
export 'src/food/portion/state_sibling.dart';
export 'src/food/portion/unit_options.dart';
export 'src/food/search/food_search_ranker.dart';
export 'src/food/search/fuzzy_index.dart';
export 'src/food/search/name_matcher.dart';
export 'src/food/search/osa_distance.dart';
export 'src/food/search/search_candidate.dart';
export 'src/ids/hlc.dart';
export 'src/ids/uuid_v7.dart';
export 'src/insights/goal_progress.dart';
export 'src/insights/progress_series.dart';
export 'src/insights/weekly_summary.dart';
export 'src/location/city_ranker.dart';
export 'src/math/rounding.dart';
export 'src/notifications/notification_planner.dart';
export 'src/notifications/notification_prefs.dart';
export 'src/nutrition/calculator.dart';
export 'src/nutrition/nutrient_field.dart';
export 'src/nutrition/nutrients.dart';
export 'src/nutrition/sanity.dart';
export 'src/nutrition/yield.dart';
export 'src/proposals/amount_step.dart';
export 'src/proposals/assumption_code.dart';
export 'src/proposals/day_hint.dart';
export 'src/proposals/proposal_input.dart'
    show
        InterpretationDecoder,
        ProposalAdd,
        ProposalAdjustment,
        ProposalBuildResult,
        ProposalCard,
        ProposalChip,
        ProposalChoiceOrigin,
        ProposalComponentEffect,
        ProposalContext,
        ProposalDayContext,
        ProposalDayPreview,
        ProposalDiff,
        ProposalDimension,
        ProposalDimensionKind,
        ProposalDraftCodec,
        ProposalEffect,
        ProposalEngine,
        ProposalEvaluation,
        ProposalEvaluationResult,
        ProposalFactOrigin,
        ProposalFacts,
        ProposalField,
        ProposalFood,
        ProposalFoodEffect,
        ProposalIdSource,
        ProposalInputException,
        ProposalIssue,
        ProposalItem,
        ProposalLifecycle,
        ProposalLine,
        ProposalOption,
        ProposalPolicy,
        ProposalQuantityEffect,
        ProposalQuestion,
        ProposalRange,
        ProposalReidentify,
        ProposalRequest,
        ProposalResult,
        ProposalRetentionEffect,
        ProposalSelect,
        ProposalServing,
        ProposalSession,
        ProposalSetAmount,
        ProposalSetLifecycle,
        ProposalSetRemoved,
        ProposalSetWhen,
        ProposalShareEffect,
        ProposalSwap,
        ProposalSyncProjection,
        ProposalUpdate,
        ProposalUpdateResult,
        QuestionBudget,
        TrustedFoodFacts;
export 'src/proposals/proposal_ops.dart';
export 'src/proposals/proposal_policy_constants.dart';
export 'src/proposals/proposal_record.dart';
export 'src/proposals/proposal_sync_codes.dart';
export 'src/quick_add/food_key.dart';
export 'src/quick_add/quick_add_ranker.dart';
export 'src/quick_add/saved_meal_matcher.dart';
export 'src/ramadan/prayer_times.dart';
export 'src/ramadan/ramadan_calendar.dart';
export 'src/ramadan/ramadan_comparison.dart';
export 'src/ramadan/ramadan_reminders.dart';
export 'src/ramadan/ramadan_settings.dart';
export 'src/ramadan/ramadan_slots.dart';
export 'src/ramadan/umm_al_qura.dart';
export 'src/settings/settings_ops.dart';
export 'src/sync/document_upgraders.dart';
export 'src/targets/adaptive_check_in.dart';
export 'src/targets/adaptive_expenditure.dart';
export 'src/targets/goals.dart';
export 'src/targets/macros.dart';
export 'src/targets/monthly_target_rate.dart';
export 'src/targets/target_calculator.dart';
export 'src/targets/target_events.dart';
export 'src/targets/target_ops.dart';
export 'src/targets/target_outcomes.dart';
export 'src/targets/target_profile.dart';
export 'src/targets/target_records.dart';
export 'src/targets/target_rules.dart';
export 'src/targets/target_settings.dart';
export 'src/targets/targets_timeline.dart';
export 'src/targets/weekly_budget.dart';
export 'src/time/clock.dart';
export 'src/time/day_pager.dart';
export 'src/time/local_date.dart';
export 'src/time/local_time.dart';
export 'src/time/week_calendar.dart';
export 'src/units/amounts.dart';
export 'src/units/display.dart';
export 'src/units/food_amount_display.dart';
export 'src/units/food_measures.dart';
export 'src/units/units.dart';
export 'src/workouts/exercise_progress.dart';
export 'src/workouts/exercise_search.dart';
export 'src/workouts/exercise_type.dart';
export 'src/workouts/log_form_draft.dart';
export 'src/workouts/muscle.dart';
export 'src/workouts/personal_records.dart';
export 'src/workouts/session_title.dart';
export 'src/workouts/set_notation.dart';
export 'src/workouts/starter_plans.dart';
export 'src/workouts/template_match.dart';
export 'src/workouts/template_update.dart';
export 'src/workouts/training_shift.dart';
export 'src/workouts/weekly_workout_summary.dart';
export 'src/workouts/workout_drafts.dart';
export 'src/workouts/workout_events.dart';
export 'src/workouts/workout_history.dart';
export 'src/workouts/workout_ops.dart';
export 'src/workouts/workout_overview.dart';
export 'src/workouts/workout_set.dart';
export 'src/workouts/workout_wire_rules.dart';
