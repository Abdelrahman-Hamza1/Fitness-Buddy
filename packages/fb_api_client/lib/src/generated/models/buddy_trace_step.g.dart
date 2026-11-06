// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_trace_step.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyTraceStep _$BuddyTraceStepFromJson(Map<String, dynamic> json) =>
    _BuddyTraceStep(
      tool: json['tool'] as String,
      args: json['args'] as String,
      resultSummary: json['resultSummary'] as String,
      ms: (json['ms'] as num).toInt(),
      tokens: (json['tokens'] as num).toInt(),
      usd: (json['usd'] as num).toDouble(),
    );

Map<String, dynamic> _$BuddyTraceStepToJson(_BuddyTraceStep instance) =>
    <String, dynamic>{
      'tool': instance.tool,
      'args': instance.args,
      'resultSummary': instance.resultSummary,
      'ms': instance.ms,
      'tokens': instance.tokens,
      'usd': instance.usd,
    };
