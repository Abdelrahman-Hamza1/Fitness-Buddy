/// A built-in exercise. Equipment variants have distinct stable IDs (WO-002).
class ExerciseSeed {
  const new({
    required this.id,
    required this.names,
    required this.type,
    required this.equipment,
    required this.primaryMuscle,
  });

  final String id;
  final List<String> names;
  final String type;
  final String equipment;
  final String primaryMuscle;
}

/// One GeoNames-derived city for offline location selection (LC-033).
class CitySeed {
  const new({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.countryCode,
    required this.admin1,
    required this.lat,
    required this.lon,
    required this.timezone,
    required this.population,
  });

  final String id;
  final String nameEn;
  final String? nameAr;
  final String countryCode;
  final String? admin1;
  final double lat;
  final double lon;
  final String timezone;
  final int? population;

  Map<String, Object?> toRow() => {
    'id': id,
    'name_en': nameEn,
    'name_ar': nameAr,
    'country_code': countryCode,
    'admin1': admin1,
    'lat': lat,
    'lon': lon,
    'timezone': timezone,
    'population': population,
  };
}
