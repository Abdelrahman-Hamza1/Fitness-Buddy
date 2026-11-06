import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/targets/presentation/targets_screen.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));
final LocalDate _sat = LocalDate(2026, 10, 24);

DayTargets _day(List<DayIntake> intake) => TargetsTimeline.day(
  date: _sat.plusDays(4),
  settings: [
    TargetSettingsRecord(
      id: '0199e3c2-5b1a-7c3d-8e4f-000000000001',
      revision: 1,
      effectiveFrom: _sat.plusDays(-14),
      baseKcal: 2000,
      basisWeightKg: 80,
    ),
  ],
  profile: const ProfileRecord(
    heightInputUnit: HeightInputUnit.centimeter,
    sex: FormulaSex.male,
    birthYear: 1990,
    heightCm: 180,
    activity: ActivityLevel.sedentary,
  ),
  intake: intake,
)!;

void main() {
  test('HM-002 the Targets week line shows "~" when an earlier counted day '
      'holds an estimate, like Today', () {
    final plain = _day([
      DayIntake(date: _sat, kcal: 2400, entryCount: 3),
      DayIntake(date: _sat.plusDays(1), kcal: 2100, entryCount: 3),
    ]);
    final marked = _day([
      DayIntake(date: _sat, kcal: 2400, entryCount: 3, estimated: true),
      DayIntake(date: _sat.plusDays(1), kcal: 2100, entryCount: 3),
    ]);
    final plainText = weekPositionText(_l10n, plain.week!);
    final markedText = weekPositionText(_l10n, marked.week!);
    expect(plainText, isNot(contains(_l10n.approx(''))));
    expect(markedText, contains(_l10n.approx('')));
    expect(
      markedText.replaceFirst(_l10n.approx(''), ''),
      plainText,
      reason: 'the same line, only marked',
    );
  });
}
