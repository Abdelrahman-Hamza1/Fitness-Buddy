import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/body.dart';
import '../helpers/property.dart';

void main() {
  Glados2(
    any.listWithLengthInRange(1, 40, any.intInRange(1, 30)),
    any.listWithLengthInRange(1, 40, any.intInRange(2000, 50001)),
    propertyRuns,
  ).test("WB-010 smoothDaily gives exactly TrendWeight's trend values for the "
      'same day choices', (gaps, hundredths) {
    final count = gaps.length < hundredths.length
        ? gaps.length
        : hundredths.length;
    var day = 0;
    final weighIns = [
      for (var i = 0; i < count; i++)
        storedOn(
          dayN(day += i == 0 ? 0 : gaps[i]),
          hundredths[i] / 100,
          id: weighInId(i),
        ),
    ];
    final trend = TrendWeight().compute(weighIns);
    final smoothed = smoothDaily([
      for (final w in weighIns) (w.localDate, w.kg),
    ], TrendWeightConfig.standard);
    expect(smoothed, [for (final p in trend.points) p.trendKg]);
  });

  test('smoothDaily: empty in, empty out; the first value sets the trend; '
      'dates must strictly increase', () {
    final config = TrendWeightConfig.standard;
    expect(smoothDaily(const [], config), isEmpty);
    expect(smoothDaily([(day0, 92)], config), [92]);
    final two = smoothDaily([(day0, 90), (dayN(7), 92)], config);
    expect(two.last, closeTo(91, 1e-12)); // a week counts half
    expect(
      () => smoothDaily([(day0, 90), (day0, 91)], config),
      throwsArgumentError,
    );
    expect(
      () => smoothDaily([(dayN(1), 90), (day0, 91)], config),
      throwsArgumentError,
    );
  });
}
