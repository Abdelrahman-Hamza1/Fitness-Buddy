// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'fb_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class FbLocalizationsEn extends FbLocalizations {
  FbLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get fbUndo => 'Undo';

  @override
  String get fbDone => 'Done';

  @override
  String get fbAnswerDefault => 'Default';

  @override
  String get fbSourceBadgeYours => 'Y';

  @override
  String get fbSourceBadgeDatabase => 'D';

  @override
  String get fbSourceBadgeReference => 'R';

  @override
  String get fbSourceBadgeEstimate => '~';

  @override
  String get fbSourceLegendTitle => 'Where numbers come from';

  @override
  String get fbSourceYoursTitle => 'Yours';

  @override
  String get fbSourceYoursBody =>
      'Numbers you entered or scanned from a label.';

  @override
  String get fbSourceDatabaseTitle => 'Food database';

  @override
  String get fbSourceDatabaseBody =>
      'Looked up in the food database, scaled to your portion.';

  @override
  String get fbSourceReferenceTitle => 'Reference dish';

  @override
  String get fbSourceReferenceBody =>
      'Typical numbers for a dish, scaled to your portion.';

  @override
  String get fbSourceEstimateTitle => 'Estimate';

  @override
  String get fbSourceEstimateBody =>
      'A rough guess. The real value could be higher or lower.';

  @override
  String get fbEstimateRangeTitle => 'Estimate';

  @override
  String get fbEstimateRangeLabel => 'Likely range';

  @override
  String get fbEstimateReasonLabel => 'Why it is an estimate';

  @override
  String get fbNumberPadBackspace => 'Delete last digit';

  @override
  String get fbNumberPadDecimal => 'Decimal point';

  @override
  String get fbInputCamera => 'Take a photo';

  @override
  String get fbInputBarcode => 'Scan a barcode';

  @override
  String get fbSearchClear => 'Clear search';

  @override
  String get fbDatePrevious => 'Previous day';

  @override
  String get fbDateNext => 'Next day';

  @override
  String get fbDateChoose => 'Choose a date';

  @override
  String get fbChartPlaceholder => 'Chart coming soon';

  @override
  String get fbSheetDragHandle => 'Drag handle';

  @override
  String get fbLoading => 'Loading';
}
