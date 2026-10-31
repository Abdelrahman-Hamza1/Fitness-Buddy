import 'package:fb_design_system/fb_design_system.dart'
    show FbBarChart, FbTimeSeriesChart;
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../features/foods/presentation/support/personal_food_support.dart'
    show useWindow;
import '../helpers/pump_app.dart';
import 'support/acceptance_app.dart';
import 'support/style_contrast.dart';

/// Collects every Flutter error (overflow, layout, build) reported while
/// [body] runs, instead of failing at the first one.
Future<void> _collectErrors(
  List<String> findings,
  String Function() where,
  Future<void> Function() body,
) async {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final first = details.exceptionAsString().split('\n').first;
    findings.add('${where()}: $first');
  };
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
}

/// The overrides of one sweep: the acceptance ones and [theme].
List<Override> _overrides(ThemePreference theme) => [
  ...acceptanceOverrides(),
  themePreferenceProvider.overrideWith((ref) => Stream.value(theme)),
];

/// Runs [check] on everything a user can reach, at the repo's phone size
/// (360 × 800 dp, narrower than the A55), at text [scale], in [theme]:
/// every route of a seeded profile scrolled through, Today's expanded meals
/// and its sheets (including all three summary slides), setup's pages on a
/// fresh profile, then Ramadan's screens
/// and day states on a profile in Ramadan (A41a). Returns the
/// number of places checked.
Future<int> _sweep(
  WidgetTester tester,
  Future<void> Function(String where) check, {
  double scale = 1,
  ThemePreference theme = ThemePreference.light,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  var places = 0;
  Future<void> counted(String where) {
    places++;
    return check(where);
  }

  useWindow(tester, width: 360, height: 800);
  final container = await pumpApp(tester, overrides: _overrides(theme));
  final seeded = await seedProfile(tester, container);
  await visitEveryRoute(tester, container, seeded, counted);
  await visitStates(tester, seeded, counted);
  await unmountApp(tester, container);
  await visitSetupPages(tester, _overrides(theme), counted);
  await visitRamadan(tester, _overrides(theme), counted);
  return places;
}

/// Android's 48 dp tap target guideline (`androidTapTargetGuideline`),
/// with two exemptions:
/// - a node clipped by its scroll view (part of it scrolled out of view: its
///   visible part is smaller than the control, which is checked at another
///   scroll stop);
/// - the data marks of a chart (a bar of the week chart is 37 dp wide on a
///   360 dp phone: seven days don't fit 48 dp each). They are larger than
///   WCAG 2.2's 24 px target minimum (2.5.8), and every value they show is
///   also in the screen's text.
final class _TapTargets extends MinimumTapTargetGuideline {
  new(this.charts)
    : super(
        size: const Size(48, 48),
        link: 'https://support.google.com/accessibility/android/answer/7101858',
      );

  /// The global rects of the charts on screen.
  final List<Rect> charts;

  @override
  bool shouldSkipNode(SemanticsNode node) {
    if (super.shouldSkipNode(node)) return true;
    final clip = node.parentPaintClipRect;
    if (clip != null && !_inside(node.rect, clip)) return true;
    if (clip != null && _touches(node.rect, clip)) return true;
    final global = _global(node);
    return charts.any((chart) => _inside(global, chart.inflate(1)));
  }

  static bool _inside(Rect child, Rect parent) =>
      parent.intersect(child) == child;

  static bool _touches(Rect child, Rect parent) =>
      (child.top - parent.top).abs() < 0.01 ||
      (child.bottom - parent.bottom).abs() < 0.01;

  static Rect _global(SemanticsNode node) {
    var rect = node.rect;
    for (SemanticsNode? n = node; n != null; n = n.parent) {
      if (n.transform case final t?) rect = MatrixUtils.transformRect(t, rect);
    }
    return rect;
  }
}

Widget _planted(Widget child) => MaterialApp(
  home: Scaffold(backgroundColor: const Color(0xFFFFFFFF), body: child),
);

void main() {
  // The sweeps' own detectors, so a green sweep means "checked", not "blind".
  testWidgets('the error collector finds a planted overflow', (tester) async {
    final findings = <String>[];
    await _collectErrors(findings, () => 'planted', () async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 40,
              child: Row(children: [SizedBox(width: 80, height: 10)]),
            ),
          ),
        ),
      );
    });
    expect(findings.single, startsWith('planted: A RenderFlex overflowed'));
  });

  testWidgets('the contrast reader finds planted low-contrast text: faint '
      'text, text in a faded dark panel, typed text, text on a field fill', (
    tester,
  ) async {
    Future<List<String>> found(Widget child) async {
      await tester.pumpWidget(_planted(child));
      return [for (final f in styleContrastFindings(tester)) f.text];
    }

    expect(
      await found(
        const Column(
          children: [
            Text('faint', style: TextStyle(color: Color(0xFFBBBBBB))),
            Text('clear', style: TextStyle(color: Color(0xFF222222))),
          ],
        ),
      ),
      ['faint'],
    );
    // White on black is 21:1, but at 50 % over white the panel shows grey:
    // about 4:1.
    expect(
      await found(
        const Opacity(
          opacity: .5,
          child: ColoredBox(
            color: Color(0xFF000000),
            child: Text('faded', style: TextStyle(color: Color(0xFFFFFFFF))),
          ),
        ),
      ),
      ['faded'],
    );
    expect(
      await found(
        TextField(
          controller: TextEditingController(text: 'typed'),
          style: const TextStyle(color: Color(0xFFBBBBBB)),
        ),
      ),
      contains('typed'),
    );
    // Dark text: fine on white, unreadable on the field's dark fill.
    expect(
      await found(
        TextField(
          controller: TextEditingController(text: 'filled'),
          style: const TextStyle(color: Color(0xFF111111)),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Color(0xFF333333),
          ),
        ),
      ),
      contains('filled'),
    );
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets('UX-070 every screen lays out at text scale $scale: no '
        'overflow or layout error on any route, scrolled through, in '
        "Today's expanded meals, its sheets, setup or Ramadan", (tester) async {
      final findings = <String>[];
      var where = 'start';
      var places = 0;
      await _collectErrors(findings, () => where, () async {
        places = await _sweep(tester, (w) async => where = w, scale: scale);
      });
      expect(findings, isEmpty, reason: findings.toSet().join('\n'));
      expect(places, greaterThan(60), reason: 'places checked');
    }, timeout: const Timeout(Duration(minutes: 8)));
  }

  testWidgets('UX-070 UX-007 at text scale 1.0 everywhere meets the 48 dp '
      'tap target guideline and shows no spinner over local data', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final findings = <String>[];
    await _sweep(tester, (where) async {
      if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
        findings.add('$where: a spinner over local data (UX-007)');
      }
      final charts = [
        for (final e
            in find
                .byWidgetPredicate(
                  (w) => w is FbBarChart || w is FbTimeSeriesChart,
                )
                .evaluate())
          if (e.renderObject case final RenderBox box when box.hasSize)
            box.localToGlobal(Offset.zero) & box.size,
      ];
      final targets = await _TapTargets(charts).evaluate(tester);
      if (!targets.passed) findings.add('$where: ${targets.reason}');
    });
    semantics.dispose();
    expect(findings, isEmpty, reason: findings.join('\n'));
  }, timeout: const Timeout(Duration(minutes: 8)));

  for (final theme in [ThemePreference.light, ThemePreference.dark]) {
    testWidgets('UX-071 every visible and typed text everywhere meets WCAG '
        'AA against what is behind it (${theme.name})', (tester) async {
      final semantics = tester.ensureSemantics();
      final findings = <String>{};
      await _sweep(tester, theme: theme, (where) async {
        for (final f in styleContrastFindings(tester)) {
          findings.add(
            '$where: "${f.text}" ${f.ratio.toStringAsFixed(2)}:1 '
            '(needs ${f.needed}:1)',
          );
        }
      });
      semantics.dispose();
      expect(findings, isEmpty, reason: findings.join('\n'));
    }, timeout: const Timeout(Duration(minutes: 8)));
  }
}
