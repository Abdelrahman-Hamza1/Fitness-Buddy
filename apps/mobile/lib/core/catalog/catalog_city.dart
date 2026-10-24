/// GeoNames city from the attached read-only pack (A05b).
final class CatalogCity {
  /// Creates catalog data without location permission or a network request.
  const new({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.countryCode,
    required this.population,
    required this.timezone,
    required this.latitude,
    required this.longitude,
  });

  /// Stable `city:<geonameid>` identity.
  final String id;

  /// English name.
  final String nameEn;

  /// Optional Arabic name.
  final String? nameAr;

  /// ISO country.
  final String countryCode;

  /// Population, including unknown/zero counts.
  final int population;

  /// IANA time zone.
  final String timezone;

  /// Latitude for A41.
  final double latitude;

  /// Longitude for A41.
  final double longitude;
}
