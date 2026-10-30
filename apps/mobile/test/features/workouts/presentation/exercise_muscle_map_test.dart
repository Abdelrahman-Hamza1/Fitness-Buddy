import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/workouts/presentation/exercise_muscle_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WO-007 every muscle maps to at least one body region', () {
    final regions = {for (final m in Muscle.values) bodyRegionOf(m)};
    // One region per muscle, none shared, all of the outline's regions used.
    expect(regions, hasLength(Muscle.values.length));
    expect(regions, FbBodyRegion.values.toSet());
    // Shoulders are the deltoids, drawn on both views (A37 D2).
    expect(bodyRegionOf(Muscle.shoulders), FbBodyRegion.deltoids);
  });
}
