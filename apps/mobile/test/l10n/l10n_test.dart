import 'dart:convert';
import 'dart:io';

import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

/// The message values of the template ARB (keys without `@`).
Set<String> _arbMessages() {
  final arb = jsonDecode(
    File('lib/l10n/app_en.arb').readAsStringSync(),
  ) as Map<String, Object?>;
  return {
    for (final MapEntry(:key, :value) in arb.entries)
      if (!key.startsWith('@')) value! as String,
  };
}

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
    final messages = _arbMessages();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.supportedLocales, [const Locale('en')]);
    expect(
      Localizations.localeOf(tester.element(find.byType(Scaffold).first)),
      const Locale('en'),
    );

    for (final route in [...AppRouter.tabs, ...AppRouter.outsideTabs]) {
      showRoute(container, route);
      await tester.pumpAndSettle();
      final texts = _visibleTexts(tester).toList();
      expect(texts, isNotEmpty, reason: route.location);
      for (final text in texts) {
        expect(
          messages,
          contains(text),
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
