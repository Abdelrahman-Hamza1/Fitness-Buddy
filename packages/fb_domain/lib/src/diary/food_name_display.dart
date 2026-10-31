import 'package:fb_domain/src/diary/diary_entry.dart';

/// The "Food names" setting (D-091, LC-*). Stored enum names are permanent
/// synced values.
enum FoodNameLanguage {
  /// Arabic when the phone's language list prefers Arabic, else English
  /// (the default; the app's own text stays English in R1, D-080).
  phone,

  /// English names.
  english,

  /// Arabic names, English where a food has none.
  arabic,

  /// The English name with the Arabic one as a second line.
  both;

  /// The language names are shown in: [phone] resolved against the
  /// phone's [languages] (language codes in preference order, e.g.
  /// `['ar', 'en']`): the first of Arabic or English wins, English when
  /// neither is listed. Never [phone].
  FoodNameLanguage resolve(Iterable<String> languages) {
    if (this != phone) return this;
    for (final code in languages) {
      switch (code.toLowerCase()) {
        case 'ar':
          return arabic;
        case 'en':
          return english;
      }
    }
    return english;
  }
}

/// How one food's names show in a row (D-091): the [primary] line and an
/// optional [secondary] line. Content-free [toString].
final class FoodNameLines {
  const new _(this.primary, this.secondary);

  /// [names] in [language] (resolved; [FoodNameLanguage.phone] reads as
  /// English). The fallback is the preferred language, then the other one;
  /// every food has an English name, so a line is never empty.
  factory of(FoodNames names, FoodNameLanguage language) {
    final ar = names.ar;
    return switch (language) {
      FoodNameLanguage.arabic => FoodNameLines._(ar ?? names.en, null),
      FoodNameLanguage.both when ar != null && ar != names.en =>
        FoodNameLines._(names.en, ar),
      _ => FoodNameLines._(names.en, null),
    };
  }

  /// The name the row leads with.
  final String primary;

  /// The other language's name, only in [FoodNameLanguage.both].
  final String? secondary;

  @override
  bool operator ==(Object other) =>
      other is FoodNameLines &&
      other.primary == primary &&
      other.secondary == secondary;

  @override
  int get hashCode => Object.hash(primary, secondary);

  @override
  String toString() =>
      'FoodNameLines(${secondary == null ? 'one line' : 'two lines'})';
}
