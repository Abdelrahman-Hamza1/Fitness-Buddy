import 'package:fb_mobile/core/navigation/navigation.dart';

/// A widget tap (UX-083, A71 D7): it only opens the app, nothing is
/// written. The names are the fixed allow-list the native side also checks
/// (`HomeWidgets.kt`, the intent actions `…fitnessbuddy.widget.<NAME>`).
enum HomeWidgetAction {
  /// The numbers: the Today tab.
  today('today'),

  /// Ask: Buddy with the keyboard.
  ask('ask'),

  /// Speak: Buddy listening (A70).
  speak('speak'),

  /// Weigh: the weigh-in pad.
  weigh('weigh');

  new(this.wire);

  /// The name on the channel.
  final String wire;

  /// The action named [wire]; null for anything else (the app just opens).
  static HomeWidgetAction? of(String? wire) =>
      values.where((a) => a.wire == wire).firstOrNull;
}

/// Where [action] opens, as a router location.
String homeWidgetLocation(HomeWidgetAction action) => switch (action) {
  HomeWidgetAction.today => const TodayRoute().location,
  HomeWidgetAction.weigh => const TodayRoute(open: TodayOpen.weighIn).location,
  HomeWidgetAction.ask => buddyFromWidgetLocation(voice: false),
  HomeWidgetAction.speak => buddyFromWidgetLocation(voice: true),
};

/// Buddy from a widget button (A71 D7), with the keyboard or listening.
///
/// Speak opens Buddy listening (A70 voice mode), Ask opens Buddy with the
/// keyboard up (A70's keyboard entry).
String buddyFromWidgetLocation({required bool voice}) =>
    TodayRoute(open: voice ? TodayOpen.buddyVoice : TodayOpen.buddy).location;
