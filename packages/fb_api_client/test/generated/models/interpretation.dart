// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'id.dart';
import 'intent.dart';

part 'interpretation.freezed.dart';
part 'interpretation.g.dart';

@Freezed()
abstract class Interpretation with _$Interpretation {
  const factory Interpretation({
    required Id id,
    required List<Intent> intents,
  }) = _Interpretation;

  factory Interpretation.fromJson(Map<String, Object?> json) =>
      _$InterpretationFromJson(json);
}
