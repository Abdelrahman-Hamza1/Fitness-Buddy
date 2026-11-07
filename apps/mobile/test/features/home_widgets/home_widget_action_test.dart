import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/home_widgets/application/home_widget_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UX-083 A71 D7 only the four fixed actions are accepted; anything '
      'else just opens the app', () {
    expect(HomeWidgetAction.of('today'), HomeWidgetAction.today);
    expect(HomeWidgetAction.of('ask'), HomeWidgetAction.ask);
    expect(HomeWidgetAction.of('speak'), HomeWidgetAction.speak);
    expect(HomeWidgetAction.of('weigh'), HomeWidgetAction.weigh);
    for (final other in [
      null,
      '',
      'Ask',
      'ask ',
      '/today',
      'today?open=buddy',
      'https://example.org',
      'log',
    ]) {
      expect(HomeWidgetAction.of(other), isNull, reason: '$other');
    }
  });

  test('UX-083 each tap opens its place: numbers → Today, Weigh → the '
      'weigh-in, Ask and Speak → Buddy (Speak like Ask until A70)', () {
    expect(homeWidgetLocation(HomeWidgetAction.today), TodayRoute.path);
    expect(
      homeWidgetLocation(HomeWidgetAction.weigh),
      const TodayRoute(open: TodayOpen.weighIn).location,
    );
    expect(
      homeWidgetLocation(HomeWidgetAction.ask),
      const TodayRoute(open: TodayOpen.buddy).location,
    );
    expect(
      homeWidgetLocation(HomeWidgetAction.speak),
      const TodayRoute(open: TodayOpen.buddyVoice).location,
    );
  });
}
