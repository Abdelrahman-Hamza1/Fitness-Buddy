// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'food_item.dart';
import 'instant.dart';
import 'intent.dart';
import 'local_date.dart';

part 'log_food_intent.freezed.dart';
part 'log_food_intent.g.dart';

@Freezed()
abstract class LogFoodIntent with _$LogFoodIntent {
  const factory LogFoodIntent({
    required String kind,
    required List<FoodItem> items,
    required Instant eatenAt,
    required LocalDate? date,
  }) = _LogFoodIntent;

  factory LogFoodIntent.fromJson(Map<String, Object?> json) =>
      _$LogFoodIntentFromJson(json);
}
