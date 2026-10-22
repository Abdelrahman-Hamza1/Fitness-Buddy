import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart' show FoodSource;

/// The design system's badge for a food's [source] (FD-010).
FbSource fbSourceOf(FoodSource source) => switch (source) {
  FoodSource.yours => FbSource.yours,
  FoodSource.database => FbSource.database,
  FoodSource.reference => FbSource.referenceDish,
  FoodSource.estimate => FbSource.estimate,
};
