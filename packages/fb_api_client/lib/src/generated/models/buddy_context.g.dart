// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyContext _$BuddyContextFromJson(Map<String, dynamic> json) =>
    _BuddyContext(
      personalFoods: (json['personalFoods'] as List<dynamic>)
          .map((e) => BuddyPersonalFood.fromJson(e as Map<String, dynamic>))
          .toList(),
      savedMeals: (json['savedMeals'] as List<dynamic>)
          .map((e) => BuddyNamedReference.fromJson(e as Map<String, dynamic>))
          .toList(),
      openBatches: (json['openBatches'] as List<dynamic>)
          .map((e) => BuddyNamedReference.fromJson(e as Map<String, dynamic>))
          .toList(),
      memory: (json['memory'] as List<dynamic>)
          .map((e) => BuddyMemory.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentEntries: (json['recentEntries'] as List<dynamic>)
          .map((e) => BuddyRecentEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      customExercises: (json['customExercises'] as List<dynamic>)
          .map((e) => BuddyNamedReference.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeCard: json['activeCard'] == null
          ? null
          : BuddyActiveCard.fromJson(
              json['activeCard'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$BuddyContextToJson(
  _BuddyContext instance,
) => <String, dynamic>{
  'personalFoods': instance.personalFoods.map((e) => e.toJson()).toList(),
  'savedMeals': instance.savedMeals.map((e) => e.toJson()).toList(),
  'openBatches': instance.openBatches.map((e) => e.toJson()).toList(),
  'memory': instance.memory.map((e) => e.toJson()).toList(),
  'recentEntries': instance.recentEntries.map((e) => e.toJson()).toList(),
  'customExercises': instance.customExercises.map((e) => e.toJson()).toList(),
  'activeCard': instance.activeCard?.toJson(),
};
