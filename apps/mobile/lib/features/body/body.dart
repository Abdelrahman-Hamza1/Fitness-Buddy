/// Weigh-ins and the weight trend (A14): the write-path handler, the read
/// providers, the weigh-in sheet and the weight card of the day pages.
/// Targets (A13) read the current weight only through
/// `currentWeightKgProvider` and `weightTrendProvider` (A14 PA1), and open
/// `showWeighInSheet` to log one.
library;

export 'application/weight_providers.dart';
export 'data/weigh_in_op_handler.dart';
export 'presentation/weigh_in_sheet.dart' show WeighInSheet, showWeighInSheet;
export 'presentation/weight_card.dart' show WeightCard;
