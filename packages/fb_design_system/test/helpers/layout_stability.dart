import 'package:flutter_test/flutter_test.dart';

/// The text scales every stability test runs at (UX-045, A57).
const stabilityScales = [1.0, 1.3, 2.0];

/// Expects [finder]'s size to be the same before and after [act]; when
/// [anchor] is given, also its global top.
Future<void> expectStable(
  WidgetTester tester,
  Finder finder,
  Future<void> Function() act, {
  Finder? anchor,
  String reason = '',
}) async {
  final size = tester.getSize(finder);
  final top = anchor == null ? null : tester.getTopLeft(anchor).dy;
  await act();
  expect(tester.getSize(finder), size, reason: '$reason size');
  if (anchor != null) {
    expect(tester.getTopLeft(anchor).dy, top, reason: '$reason anchor top');
  }
}
