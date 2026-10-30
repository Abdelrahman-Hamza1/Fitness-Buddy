import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/week_calendar.dart';
import 'package:fb_domain/src/workouts/template_match.dart';
import 'package:fb_domain/src/workouts/workout_drafts.dart';
import 'package:fb_domain/src/workouts/workout_ops.dart';

/// The templates starter plans copy (WO-023). The app names each in the
/// user's language when it copies them; afterwards they're ordinary,
/// editable templates.
enum StarterTemplate {
  /// Full body A.
  fullBodyA([
    (exerciseId: 'ex:barbell_back_squat', sets: 3, reps: 5),
    (exerciseId: 'ex:barbell_bench_press', sets: 3, reps: 5),
    (exerciseId: 'ex:barbell_row', sets: 3, reps: 8),
    (exerciseId: 'ex:seated_dumbbell_shoulder_press', sets: 3, reps: 10),
    (exerciseId: 'ex:hanging_leg_raise', sets: 3, reps: 10),
  ]),

  /// Full body B.
  fullBodyB([
    (exerciseId: 'ex:barbell_deadlift', sets: 3, reps: 5),
    (exerciseId: 'ex:incline_dumbbell_bench_press', sets: 3, reps: 10),
    (exerciseId: 'ex:lat_pulldown', sets: 3, reps: 10),
    (exerciseId: 'ex:dumbbell_walking_lunge', sets: 3, reps: 10),
    (exerciseId: 'ex:cable_crunch', sets: 3, reps: 12),
  ]),

  /// Upper A.
  upperA([
    (exerciseId: 'ex:barbell_bench_press', sets: 4, reps: 6),
    (exerciseId: 'ex:barbell_row', sets: 4, reps: 6),
    (exerciseId: 'ex:seated_dumbbell_shoulder_press', sets: 3, reps: 10),
    (exerciseId: 'ex:lat_pulldown', sets: 3, reps: 10),
    (exerciseId: 'ex:dumbbell_curl', sets: 3, reps: 12),
  ]),

  /// Lower A.
  lowerA([
    (exerciseId: 'ex:barbell_back_squat', sets: 4, reps: 6),
    (exerciseId: 'ex:barbell_romanian_deadlift', sets: 3, reps: 8),
    (exerciseId: 'ex:leg_press', sets: 3, reps: 10),
    (exerciseId: 'ex:lying_leg_curl', sets: 3, reps: 12),
    (exerciseId: 'ex:standing_calf_raise', sets: 3, reps: 12),
  ]),

  /// Upper B.
  upperB([
    (exerciseId: 'ex:incline_dumbbell_bench_press', sets: 3, reps: 10),
    (exerciseId: 'ex:seated_cable_row', sets: 3, reps: 10),
    (exerciseId: 'ex:standing_barbell_overhead_press', sets: 3, reps: 8),
    (exerciseId: 'ex:pull_up', sets: 3, reps: 8),
    (exerciseId: 'ex:rope_triceps_pushdown', sets: 3, reps: 12),
    (exerciseId: 'ex:hammer_curl', sets: 3, reps: 12),
  ]),

  /// Lower B.
  lowerB([
    (exerciseId: 'ex:barbell_deadlift', sets: 3, reps: 5),
    (exerciseId: 'ex:dumbbell_bulgarian_split_squat', sets: 3, reps: 10),
    (exerciseId: 'ex:leg_extension', sets: 3, reps: 12),
    (exerciseId: 'ex:seated_leg_curl', sets: 3, reps: 12),
    (exerciseId: 'ex:seated_calf_raise', sets: 3, reps: 15),
  ]),

  /// Push.
  push([
    (exerciseId: 'ex:barbell_bench_press', sets: 3, reps: 8),
    (exerciseId: 'ex:standing_barbell_overhead_press', sets: 3, reps: 8),
    (exerciseId: 'ex:incline_dumbbell_bench_press', sets: 3, reps: 10),
    (exerciseId: 'ex:dumbbell_lateral_raise', sets: 3, reps: 15),
    (exerciseId: 'ex:rope_triceps_pushdown', sets: 3, reps: 12),
  ]),

  /// Pull.
  pull([
    (exerciseId: 'ex:barbell_row', sets: 3, reps: 8),
    (exerciseId: 'ex:lat_pulldown', sets: 3, reps: 10),
    (exerciseId: 'ex:seated_cable_row', sets: 3, reps: 10),
    (exerciseId: 'ex:cable_face_pull', sets: 3, reps: 15),
    (exerciseId: 'ex:dumbbell_curl', sets: 3, reps: 12),
  ]),

  /// Legs.
  legs([
    (exerciseId: 'ex:barbell_back_squat', sets: 3, reps: 8),
    (exerciseId: 'ex:barbell_romanian_deadlift', sets: 3, reps: 10),
    (exerciseId: 'ex:leg_press', sets: 3, reps: 12),
    (exerciseId: 'ex:lying_leg_curl', sets: 3, reps: 12),
    (exerciseId: 'ex:standing_calf_raise', sets: 3, reps: 15),
  ]);

  new(this.items);

  /// The lines, in order (built-in exercise IDs, which never change,
  /// TD-071).
  final List<TemplateTarget> items;
}

/// The optional starter plans gallery (WO-023, D-085, A37 D18). "Build my
/// own" isn't a plan: it opens an empty template.
enum StarterPlan {
  /// Full body, 3 days: A, B, A.
  fullBody(
    templates: [StarterTemplate.fullBodyA, StarterTemplate.fullBodyB],
    minDays: 3,
    maxDays: 3,
    defaultOffsets: [0, 2, 4],
  ),

  /// Upper/Lower, 4 days.
  upperLower(
    templates: [
      StarterTemplate.upperA,
      StarterTemplate.lowerA,
      StarterTemplate.upperB,
      StarterTemplate.lowerB,
    ],
    minDays: 4,
    maxDays: 4,
    defaultOffsets: [0, 1, 3, 4],
  ),

  /// Push/Pull/Legs, 3 to 6 days, cycling.
  pushPullLegs(
    templates: [
      StarterTemplate.push,
      StarterTemplate.pull,
      StarterTemplate.legs,
    ],
    minDays: 3,
    maxDays: 6,
    defaultOffsets: [0, 2, 4],
  );

  new({
    required this.templates,
    required this.minDays,
    required this.maxDays,
    required this.defaultOffsets,
  });

  /// The templates it copies, in rotation order.
  final List<StarterTemplate> templates;

  /// Fewest training days.
  final int minDays;

  /// Most training days.
  final int maxDays;

  /// The default training days, as days after the week start.
  final List<int> defaultOffsets;

  /// Whether [count] training days fit.
  bool fits(int count) => count >= minDays && count <= maxDays;

  /// The default training days for weeks starting on [weekStart].
  List<DayOfWeek> defaultDays(DayOfWeek weekStart) {
    final order = WeekCalendar(weekStart: weekStart).daysInOrder;
    return [for (final offset in defaultOffsets) order[offset]];
  }

  /// Which template each of [days] trains: the rotation cycles over the
  /// days in week order (weeks starting on [weekStart]), so PPL on four
  /// days is Push, Pull, Legs, Push. Throws an `ArgumentError` when the
  /// number of distinct days doesn't [fits].
  Map<DayOfWeek, StarterTemplate> assign(
    Iterable<DayOfWeek> days, {
    required DayOfWeek weekStart,
  }) {
    final picked = days.toSet();
    if (!fits(picked.length)) {
      throw ArgumentError.value(picked.length, 'days', 'out of range');
    }
    final ordered = [
      for (final day in WeekCalendar(weekStart: weekStart).daysInOrder)
        if (picked.contains(day)) day,
    ];
    return {
      for (final (i, day) in ordered.indexed)
        day: templates[i % templates.length],
    };
  }

  /// The one change set that applies this plan (A37 D18, PA4): a
  /// `CreateWorkoutTemplate` per template (named by [nameOf], new IDs from
  /// [ids]), then a `SetPlanDay` for all seven weekdays: the picked [days]
  /// train their template, every other day rests. Applied together, it
  /// either all lands or none of it does, and its inverse is one undo.
  List<WorkoutOp> ops({
    required Iterable<DayOfWeek> days,
    required DayOfWeek weekStart,
    required IdGenerator ids,
    required String Function(StarterTemplate template) nameOf,
  }) {
    final assigned = assign(days, weekStart: weekStart);
    final templateIds = <StarterTemplate, String>{};
    final creates = <WorkoutOp>[
      for (final template in templates)
        CreateWorkoutTemplate(
          templateIds[template] = ids.next(),
          WorkoutTemplateDraft(
            name: nameOf(template),
            items: [
              for (final item in template.items)
                TemplateItemDraft(
                  id: ids.next(),
                  exerciseId: item.exerciseId,
                  sets: item.sets,
                  reps: item.reps,
                ),
            ],
          ),
        ),
    ];
    return [
      ...creates,
      for (final day in DayOfWeek.values)
        SetPlanDay(day, switch (assigned[day]) {
          final template? => templateIds[template],
          null => null,
        }),
    ];
  }
}

/// A template draft's lines as targets (for "save as template" and the
/// template-update offer, WO-020, WO-022).
List<TemplateTarget> templateTargetsOf(WorkoutTemplateDraft template) => [
  for (final item in template.items)
    (exerciseId: item.exerciseId, sets: item.sets, reps: item.reps),
];

/// What a session did, per exercise, for [TemplateMatch] (WO-020, WO-022).
List<SessionExerciseDone> sessionDoneOf(WorkoutSessionDraft session) => [
  for (final e in session.exercises)
    (exerciseId: e.exerciseId, reps: [for (final s in e.sets) s.values.reps]),
];
