import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_support.dart';

/// The FbButton labelled [label].
Finder _button(String label) => find.widgetWithText(FbButton, label);

/// Opens the Progress tab.
Future<void> _openProgress(WidgetTester tester) async {
  await tapExactly(
    tester,
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Progress'),
    ),
    'the Progress tab',
  );
  await pumpFor(tester, const Duration(milliseconds: 400));
}

/// Waits for [finder] to show.
Future<void> _see(WidgetTester tester, Finder finder, String what) =>
    waitUntil(tester, () => finder.evaluate().isNotEmpty, what);

/// Waits for the one text field inside [scope] (a sheet whose form loads
/// asynchronously), then types [text] into it.
Future<void> _typeIn(WidgetTester tester, Finder scope, String text) async {
  final field = find.descendant(of: scope, matching: find.byType(TextField));
  await _see(tester, field, 'the text field');
  await tester.enterText(field, text);
  await pumpFor(tester, const Duration(milliseconds: 200));
}

/// Waits until the FbButton labelled [label] is enabled, then taps it.
Future<void> _tapEnabled(WidgetTester tester, String label) async {
  final button = _button(label);
  await waitUntil(
    tester,
    () =>
        button.evaluate().isNotEmpty &&
        tester.widget<FbButton>(button).onPressed != null,
    '$label enabled',
  );
  await tapExactly(tester, button, label);
}

/// Scrolls the screen of type [screen] until [target] is built (lazy list
/// children below the fold aren't), waiting first for its data.
Future<void> _scrollTo(
  WidgetTester tester,
  Finder target,
  Type screen,
  String what,
) async {
  await pumpFor(tester, const Duration(milliseconds: 300));
  await tester.scrollUntilVisible(
    target,
    150,
    maxScrolls: 40,
    scrollable: find
        .descendant(of: find.byType(screen), matching: find.byType(Scrollable))
        .first,
  );
  await _see(tester, target, what);
}

/// Taps the entry row titled [title] on the type screen.
Future<void> _tapEntry(WidgetTester tester, String title) async {
  final row = find.widgetWithText(FbListRow, title);
  await _scrollTo(tester, row, MeasurementTypeScreen, 'the $title entry');
  await tapExactly(tester, row, 'the $title entry');
}

/// Scrolls the history until row [rowKey]'s value field is built, then
/// types [text] into it (rows are lazy list children: never by index).
Future<void> _typeRow(WidgetTester tester, int rowKey, String text) async {
  final field = find.descendant(
    of: find.byKey(WeightHistoryScreen.valueKey(rowKey)),
    matching: find.byType(TextField),
  );
  await tester.scrollUntilVisible(
    field,
    120,
    scrollable: find
        .descendant(
          of: find.byType(WeightHistoryScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await pumpFor(tester, const Duration(milliseconds: 200));
  await tester.enterText(field, text);
  await pumpFor(tester, const Duration(milliseconds: 200));
}

/// A15b on the device (WP11): body measurements and the weight history,
/// offline, on a throw-away profile.
void main() {
  patrolTest(
    'A15b measurements: add, edit, delete with undo, custom type graph',
    ($) async {
      await bootApp($, 'it-measurements', rootName: 'fb_measurements_it');
      final tester = $.tester;
      await _openProgress(tester);
      await tapExactly(tester, find.text('Measurements'), 'Measurements');
      await _see(tester, find.byType(MeasurementsScreen), 'the list');

      // Add a waist entry.
      await _tapEnabled(tester, 'Add measurement');
      await _see(tester, find.byType(MeasurementSheet), 'the sheet');
      await _typeIn(tester, find.byType(MeasurementSheet), '92');
      await _tapEnabled(tester, 'Save');
      await _see(tester, find.text('Waist saved: 92.0 cm'), 'the snackbar');
      await _see(tester, find.textContaining('Latest 92.0 cm'), 'the row');

      // Edit it on its screen.
      await tapExactly(tester, find.text('Waist'), 'the Waist row');
      await _see(tester, find.byType(FbTimeSeriesChart), 'the waist graph');
      await _tapEntry(tester, '92.0 cm');
      await _see(tester, find.text('Edit measurement'), 'the edit sheet');
      await _typeIn(tester, find.byType(MeasurementSheet), '91');
      await _tapEnabled(tester, 'Save');
      await _see(tester, find.text('Waist updated: 91.0 cm'), 'the update');

      // Delete it from the sheet, then undo.
      await _tapEntry(tester, '91.0 cm');
      await _tapEnabled(tester, 'Delete');
      await _see(tester, find.text('Entry deleted'), 'the delete snackbar');
      await tapExactly(tester, find.text('Undo'), 'Undo');
      await _scrollTo(
        tester,
        find.widgetWithText(FbListRow, '91.0 cm'),
        MeasurementTypeScreen,
        'the restored entry',
      );

      // A custom type with its own graph.
      await tester.pageBack();
      await pumpFor(tester, const Duration(milliseconds: 400));
      final addCustom = _button('Add custom measurement');
      await _scrollTo(
        tester,
        addCustom,
        MeasurementsScreen,
        'Add custom measurement',
      );
      await tapExactly(tester, addCustom, 'Add custom measurement');
      await _see(tester, find.text('New measurement'), 'the name sheet');
      await _typeIn(tester, find.byType(CustomTypeSheet), 'Left calf');
      await _tapEnabled(tester, 'Save');
      await _see(tester, find.byType(MeasurementSheet), 'its form');
      await _typeIn(tester, find.byType(MeasurementSheet), '40');
      await _tapEnabled(tester, 'Save');
      await _see(
        tester,
        find.text('Left calf saved: 40.0 cm'),
        'the custom snackbar',
      );
      final row = find.widgetWithText(FbListRow, 'Left calf');
      await _scrollTo(tester, row, MeasurementsScreen, 'the Left calf row');
      await tapExactly(tester, row, 'the Left calf row');
      await _see(tester, find.byType(FbTimeSeriesChart), 'the custom graph');
      expect(
        tester
            .widget<FbTimeSeriesChart>(find.byType(FbTimeSeriesChart))
            .series
            .first
            .points,
        hasLength(1),
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  patrolTest(
    'A15b weight history: add three past weigh-ins, see them on the graph, '
    'undo',
    ($) async {
      await bootApp($, 'it-weight-history', rootName: 'fb_weight_history_it');
      final tester = $.tester;
      await _openProgress(tester);
      await tapExactly(tester, find.text('Weight graph'), 'Weight graph');
      await _see(tester, find.byType(WeightGraphScreen), 'the graph');
      await tapExactly(
        tester,
        _button('Add past weigh-ins'),
        'the empty state action',
      );
      await _see(tester, find.byType(WeightHistoryScreen), 'the history');

      // The 1st of this month (never after today), then a week apart
      // (capped at today).
      await tapExactly(tester, find.text('Pick a date'), 'the date chip');
      await _see(tester, find.byType(Dialog), 'the date picker');
      await tapExactly(
        tester,
        find.descendant(of: find.byType(Dialog), matching: find.text('1')),
        'day 1',
      );
      await tapExactly(tester, find.text('OK'), 'OK');
      await pumpFor(tester, const Duration(milliseconds: 400));
      await _typeRow(tester, 0, '97.0');
      for (final (rowKey, value) in [(1, '96.8'), (2, '96.5')]) {
        final addRow = _button('Add row');
        await tester.scrollUntilVisible(
          addRow,
          120,
          scrollable: find
              .descendant(
                of: find.byType(WeightHistoryScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tapExactly(tester, addRow, 'Add row');
        await pumpFor(tester, const Duration(milliseconds: 300));
        await _typeRow(tester, rowKey, value);
      }
      await _see(tester, find.text('3 weigh-ins to save'), 'the count');
      await _tapEnabled(tester, 'Save');
      await _see(tester, find.byType(FbTimeSeriesChart), 'the graph');
      await _see(tester, find.text('3 weigh-ins added'), 'the snackbar');
      expect(
        tester
            .widget<FbTimeSeriesChart>(find.byType(FbTimeSeriesChart))
            .series
            .first
            .points,
        hasLength(3),
      );

      await tapExactly(tester, find.text('Undo'), 'Undo');
      await _see(tester, find.text('No weigh-ins yet'), 'the empty graph');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
