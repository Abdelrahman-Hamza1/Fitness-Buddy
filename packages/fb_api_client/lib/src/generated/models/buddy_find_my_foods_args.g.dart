// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_find_my_foods_args.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyFindMyFoodsArgs _$BuddyFindMyFoodsArgsFromJson(
  Map<String, dynamic> json,
) => _BuddyFindMyFoodsArgs(
  query: json['query'] as String,
  kinds: (json['kinds'] as List<dynamic>)
      .map((e) => BuddyPersonalKind.fromJson(e as String))
      .toList(),
);

Map<String, dynamic> _$BuddyFindMyFoodsArgsToJson(
  _BuddyFindMyFoodsArgs instance,
) => <String, dynamic>{
  'query': instance.query,
  'kinds': instance.kinds.map((e) => _$BuddyPersonalKindEnumMap[e]!).toList(),
};

const _$BuddyPersonalKindEnumMap = {
  BuddyPersonalKind.personalFood: 'personalFood',
  BuddyPersonalKind.savedMeal: 'savedMeal',
  BuddyPersonalKind.batch: 'batch',
  BuddyPersonalKind.usual: 'usual',
  BuddyPersonalKind.$unknown: r'$unknown',
};
