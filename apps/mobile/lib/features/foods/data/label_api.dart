import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart' as api;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/api/auth_interceptor.dart';
import 'package:fb_mobile/core/api/failure_mapper.dart';
import 'package:fb_mobile/core/errors/failure.dart';
import 'package:fb_mobile/features/foods/application/label_reading.dart';
import 'package:fb_mobile/features/foods/application/personal_food_form.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'label_api.g.dart';

/// `POST /v1/buddy/label` (B26, FD-040–042) over the generated client, on
/// a clone of the app dio that waits up to [receiveTimeout] for the
/// vision read. Never throws; the photo and the values are never logged.
final class LabelApi {
  /// Calls through [dio] (the app's API dio).
  new(Dio dio) {
    final clone = dio.clone(
      options: dio.options.copyWith(
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
      ),
      interceptors: Interceptors(),
    );
    clone.interceptors.addAll([
      for (final i in dio.interceptors)
        if (i is AuthInterceptor) i.forDio(clone) else i,
    ]);
    _client = api.BuddyClient(clone);
  }

  /// A vision read takes seconds.
  static const receiveTimeout = Duration(seconds: 45);

  /// A photo is up to 300 KB.
  static const sendTimeout = Duration(seconds: 30);

  late final api.BuddyClient _client;

  /// The label in [image] (base64 JPEG, ≤ 1024 px).
  Future<LabelOutcome> read(String image) async {
    try {
      final read = await _client.extractBuddyLabel(
        body: api.BuddyLabelRequest(image: image),
      );
      final reading = labelReadingOf(read);
      return reading == null
          ? const LabelNotRead(LabelFailure.notFound)
          : LabelRead(reading);
    } on DioException catch (error) {
      return LabelNotRead(switch (FailureMapper.fromDio(error)) {
        RateLimitedFailure() => LabelFailure.limited,
        OfflineFailure() => LabelFailure.offline,
        _ => LabelFailure.unavailable,
      });
      // A malformed answer is a read that didn't work (its content never
      // leaves here).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return const LabelNotRead(LabelFailure.unavailable);
    }
  }

  @override
  String toString() => 'LabelApi';
}

/// [read] as the review form's input, or `null` when no panel was read.
/// A field is uncertain when its confidence is medium or low, it is
/// missing, or code converted it (kJ → kcal, salt → sodium).
LabelReading? labelReadingOf(api.BuddyLabelExtraction read) {
  final basis = read.basis;
  if (!read.found || basis == null) return null;
  final n = read.nutrients;
  final serving = read.serving;
  final perServing = basis == api.BuddyLabelBasis.perServing;
  final ml =
      basis == api.BuddyLabelBasis.per100ml ||
      (perServing && serving?.g == null && serving?.ml != null);
  bool sure(api.BuddyLabelConfidence c) => c == api.BuddyLabelConfidence.high;
  final fields = <PersonalFoodField, api.BuddyLabelValue>{
    PersonalFoodField.kcal: n.kcal,
    PersonalFoodField.protein: n.proteinG,
    PersonalFoodField.carbs: n.carbsG,
    PersonalFoodField.fat: n.fatG,
    PersonalFoodField.fiber: n.fiberG,
    PersonalFoodField.sugar: n.sugarG,
    PersonalFoodField.saturatedFat: n.saturatedFatG,
    PersonalFoodField.transFat: n.transFatG,
    PersonalFoodField.sodium: n.sodiumMg,
    PersonalFoodField.cholesterol: n.cholesterolMg,
  };
  const core = {
    PersonalFoodField.kcal,
    PersonalFoodField.protein,
    PersonalFoodField.carbs,
    PersonalFoodField.fat,
  };
  final size = perServing ? (ml ? serving?.ml : serving?.g) : null;
  final name = read.name.value?.trim();
  return LabelReading(
    basis: ml ? NutrientBasis.per100ml : NutrientBasis.per100g,
    perServing: perServing,
    servingSize: size,
    name: name == null || name.isEmpty ? null : name,
    values: {
      for (final MapEntry(:key, :value) in fields.entries) key: ?value.value,
    },
    uncertain: {
      for (final MapEntry(:key, :value) in fields.entries)
        if ((value.value == null && core.contains(key)) ||
            (value.value != null && !sure(value.confidence)))
          key,
      if (n.kcalFromKj) PersonalFoodField.kcal,
      if (n.sodiumFromSalt) PersonalFoodField.sodium,
      if (name == null || name.isEmpty || !sure(read.name.confidence))
        PersonalFoodField.name,
      if (perServing &&
          (size == null || serving == null || !sure(serving.confidence)))
        PersonalFoodField.servingSize,
    },
    others: [for (final o in read.others) LabelOther(o.name, o.value, o.unit)],
  );
}

/// The label route on the app dio.
@riverpod
LabelApi labelApi(Ref ref) => LabelApi(ref.watch(dioProvider));
