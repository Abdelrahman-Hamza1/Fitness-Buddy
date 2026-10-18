import 'dart:convert';
import 'dart:io';

import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

/// The message values of the template ARB [path] (keys without `@`).
Set<String> _arbMessages([String path = 'lib/l10n/app_en.arb']) {
  final arb = jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  return {
    for (final MapEntry(:key, :value) in arb.entries)
      if (!key.startsWith('@')) value! as String,
  };
}

/// The fake data of the design preview's mockups, as the strings it holds
/// (adjacent literals joined): data, not UI strings (A02 D15).
Set<String> _fakeDataStrings() {
  final source = File('lib/features/design_preview/application/fake_data.dart')
      .readAsStringSync();
  return {
    for (final m in RegExp(r"(?:'[^'\n]*'\s*)+").allMatches(source))
      RegExp(r"'([^'\n]*)'")
          .allMatches(m.group(0)!)
          .map((x) => x.group(1))
          .join(),
  };
}

/// Whether [text] is a message of the ARB [messages] with its `{placeholders}`
/// filled in (product copy with pre-formatted numbers, e.g. "This week: 350
/// under").
bool _matchesTemplate(Set<String> messages, String text) => messages.any(
  (m) =>
      m.contains('{') &&
      RegExp('^${RegExp.escape(m).replaceAll(RegExp(r'\\\{\w+\\\}'), '.+')}\$')
          .hasMatch(text),
);

/// Every string shown by a [Text] on screen right now.
Iterable<String> _visibleTexts(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan!.toPlainText());

void main() {
  test('LC-002 the only supported locale is English', () {
    expect(AppLocalizations.supportedLocales, [const Locale('en')]);
    expect(
      FitnessBuddyApp.localizationsDelegates,
      contains(AppLocalizations.delegate),
    );
  });

  testWidgets('LC-002 app supports only en and every visible string comes from '
      'AppLocalizations', (tester) async {
    // Even on a phone set to Arabic, R1 shows the English UI.
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.platformDispatcher.localesTestValue = [const Locale('ar')];
    final container = await pumpApp(tester);
    // The design system's built-in strings (A02 D5) count too.
    final messages = {
      ..._arbMessages(),
      ..._arbMessages('../../packages/fb_design_system/lib/l10n/fb_ds_en.arb'),
    };

    final fakeData = _fakeDataStrings();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.supportedLocales, [const Locale('en')]);
    expect(
      Localizations.localeOf(tester.element(find.byType(Scaffold).first)),
      const Locale('en'),
    );

    // The design preview's chrome and Mockups tab (its first) are app strings
    // too; the gallery's sample content is data (A02 D15).
    for (final route in [
      ...AppRouter.tabs,
      ...AppRouter.outsideTabs,
      const DesignPreviewRoute(),
    ]) {
      showRoute(container, route);
      await tester.pumpAndSettle();
      final texts = _visibleTexts(tester).toList();
      expect(texts, isNotEmpty, reason: route.location);
      for (final text in texts) {
        expect(
          messages.contains(text) ||
              fakeData.contains(text) ||
              _matchesTemplate(messages, text),
          isTrue,
          reason: '"$text" on ${route.location} is not in app_en.arb',
        );
      }
    }
  });

  testWidgets('LC-002 material_ui widgets get Material localizations', (
    tester,
  ) async {
    await pumpApp(tester);
    final context = tester.element(find.byType(Scaffold).first);
    expect(MaterialLocalizations.of(context).okButtonLabel, 'OK');
    expect(context.l10n.tabToday, 'Today');
    expect(const TodayRoute().location, '/today');
  });
}
