// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'ask_question_intent.dart';
import 'food_item.dart';
import 'instant.dart';
import 'local_date.dart';
import 'log_food_intent.dart';
import 'unknown_intent.dart';

part 'intent.freezed.dart';
part 'intent.g.dart';

@Freezed(unionKey: 'kind', fallbackUnion: 'unrecognized')
sealed class Intent with _$Intent {
  @FreezedUnionValue('logFood')
  const factory Intent.logFood({
    required String kind,
    required List<FoodItem> items,
    required Instant eatenAt,
    required LocalDate? date,
  }) = IntentLogFood;

  @FreezedUnionValue('askQuestion')
  const factory Intent.askQuestion({
    required String kind,
    required String question,
    required String? topic,
  }) = IntentAskQuestion;

  @FreezedUnionValue('unknown')
  const factory Intent.unknown({
    required String kind,
    required String? reason,
  }) = IntentUnknown;

  const factory Intent.unrecognized() = IntentUnrecognized;

  factory Intent.fromJson(Map<String, Object?> json) => _$IntentFromJson(json);
}
