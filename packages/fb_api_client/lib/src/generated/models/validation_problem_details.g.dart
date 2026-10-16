// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validation_problem_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ValidationProblemDetails _$ValidationProblemDetailsFromJson(
  Map<String, dynamic> json,
) => _ValidationProblemDetails(
  type: json['type'] as String,
  title: json['title'] as String,
  status: (json['status'] as num).toInt(),
  errors: (json['errors'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
  ),
  detail: json['detail'] as String?,
  instance: json['instance'] as String?,
  traceId: json['traceId'] as String?,
);

Map<String, dynamic> _$ValidationProblemDetailsToJson(
  _ValidationProblemDetails instance,
) => <String, dynamic>{
  'type': instance.type,
  'title': instance.title,
  'status': instance.status,
  'errors': instance.errors,
  'detail': instance.detail,
  'instance': instance.instance,
  'traceId': instance.traceId,
};
