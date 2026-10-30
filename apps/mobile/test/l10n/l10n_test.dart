import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('LC-002 the only supported locale is English', () {
    expect(AppLocalizations.supportedLocales, [const Locale('en')]);
    expect(
      FitnessBuddyApp.localizationsDelegates,
      contains(AppLocalizations.delegate),
    );
  });
}
