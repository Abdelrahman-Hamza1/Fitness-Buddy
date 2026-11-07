import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:fb_mobile/features/buddy/data/speech_recognizer.dart';
import 'package:fb_mobile/features/buddy/presentation/buddy_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/buddy_harness.dart';
import '../support/buddy_widgets.dart';
import '../support/fake_speech.dart';

EditableText _box(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

void main() {
  testWidgets('AI-014 the transcript lands in the box after the typed text, '
      'focused, and is never sent by itself', (tester) async {
    final speech = FakeSpeechRecognizer();
    final h = BuddyHarness(overrides: fakeSpeech(speech));
    await pumpBuddyHost(tester, h);
    await openBuddySheet(tester);
    await tester.enterText(find.byType(TextField), 'lunch:');
    await tester.tap(find.byTooltip('Speak to Buddy'));
    await tester.pumpAndSettle();
    expect(find.text('Listening…'), findsOneWidget);
    expect(speech.listened, [VoiceLanguage.english]);

    speech.hear('a chicken shawarma');
    // The event, then the frame.
    await tester.pump();
    await tester.pump();
    expect(find.text('a chicken shawarma'), findsOneWidget);
    speech.hear('a chicken shawarma and a laban');
    await tester.tap(find.byKey(const ValueKey('voice-done')));
    await tester.pump();
    expect(speech.stops, 1);
    speech.end();
    await tester.pumpAndSettle();

    // The panel is gone; the words are in the box, after the typed text.
    expect(find.text('Listening…'), findsNothing);
    final box = _box(tester);
    expect(box.controller.text, 'lunch: a chicken shawarma and a laban');
    expect(box.focusNode.hasFocus, isTrue);
    expect(
      find.text('From your voice: fix anything, then send.'),
      findsOneWidget,
    );
    // Nothing went out: no chat row, no request.
    await settleBuddy(tester);
    expect(await h.chat(), isEmpty);
    expect(h.bodies, isEmpty);

    // Send is the user's tap; the sent text is the box's as is.
    await tester.tap(find.byTooltip('Send'));
    await settleBuddy(tester);
    final rows = await h.chat();
    expect(
      rows.firstWhere((r) => r.role == 'user').messageText,
      'lunch: a chicken shawarma and a laban',
    );
    expect(
      find.text('From your voice: fix anything, then send.'),
      findsNothing,
    );
    await unmountBuddy(tester, h);
  });

  testWidgets('AI-014 microphone refused: a plain message, then the keyboard', (
    tester,
  ) async {
    final speech = FakeSpeechRecognizer(
      allowed: false,
      readiness: SpeechReadiness.denied,
    );
    final h = BuddyHarness(overrides: fakeSpeech(speech));
    await pumpBuddyHost(tester, h);
    await openBuddySheet(tester);
    await tester.tap(find.byTooltip('Speak to Buddy'));
    await tester.pumpAndSettle();
    // The plain explanation comes before the system dialog.
    expect(find.textContaining('may use the internet'), findsOneWidget);
    expect(speech.prepares, 0);
    await tester.tap(find.byKey(const ValueKey('voice-allow')));
    await tester.pumpAndSettle();
    expect(find.textContaining('microphone access is off'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(speech.listened, isEmpty);

    await tester.tap(find.byKey(const ValueKey('voice-type')));
    await tester.pumpAndSettle();
    final box = _box(tester);
    expect(box.controller.text, isEmpty);
    expect(box.focusNode.hasFocus, isTrue);
    expect(
      find.text('From your voice: fix anything, then send.'),
      findsNothing,
    );
    await unmountBuddy(tester, h);
  });

  testWidgets('A70 BuddyEntry voice opens Buddy listening at once', (
    tester,
  ) async {
    final speech = FakeSpeechRecognizer();
    final h = BuddyHarness(overrides: fakeSpeech(speech));
    await pumpBuddyHost(tester, h, mode: BuddyEntryMode.voice);
    await openBuddySheet(tester);
    expect(find.text('Listening…'), findsOneWidget);
    expect(speech.listened, hasLength(1));
    // Cancel drops the recording; the box stays empty and focused.
    speech.hear('two eggs');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('voice-cancel')));
    await tester.pumpAndSettle();
    expect(speech.cancels, greaterThanOrEqualTo(1));
    expect(_box(tester).controller.text, isEmpty);
    expect(_box(tester).focusNode.hasFocus, isTrue);
    await unmountBuddy(tester, h);
  });

  testWidgets('A70 the listening panel fits at text scale 2', (tester) async {
    final speech = FakeSpeechRecognizer();
    final h = BuddyHarness(overrides: fakeSpeech(speech));
    await pumpBuddyHost(tester, h, mode: BuddyEntryMode.voice, textScale: 2);
    await openBuddySheet(tester);
    speech.hear(
      'had a chicken shawarma sandwich and a laban for lunch and '
      'then a coffee with milk and two dates',
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('shawarma sandwich'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('voice-done')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('voice-cancel')));
    await tester.pumpAndSettle();
    await unmountBuddy(tester, h);
  });

  testWidgets('A70 review 4 dismissing the panel cancels at once; a late '
      'result never closes Buddy or its draft', (tester) async {
    final speech = FakeSpeechRecognizer()..lateEvents = true;
    final h = BuddyHarness(overrides: fakeSpeech(speech));
    await pumpBuddyHost(tester, h, disableAnimations: false);
    await openBuddySheet(tester);
    await tester.enterText(find.byType(TextField), 'tea');
    await tester.tap(find.byTooltip('Speak to Buddy'));
    await tester.pumpAndSettle();
    speech.hear('two eggs');
    await tester.pump();
    // Back: the panel starts its exit transition.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(speech.cancels, 1);
    // The platform's final result arrives during the transition.
    speech
      ..hear('two eggs and toast')
      ..end();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.byType(BuddySheet), findsOneWidget);
    expect(_box(tester).controller.text, 'tea');
    expect(
      find.text('From your voice: fix anything, then send.'),
      findsNothing,
    );
    await unmountBuddy(tester, h);
  });

  testWidgets('A70 review 2 going to the background stops listening; '
      'Try again listens again', (tester) async {
    final speech = FakeSpeechRecognizer();
    final h = BuddyHarness(overrides: fakeSpeech(speech));
    await pumpBuddyHost(tester, h, mode: BuddyEntryMode.voice);
    await openBuddySheet(tester);
    expect(find.text('Listening…'), findsOneWidget);
    // The permission dialog's kind of change (inactive) keeps listening.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(speech.cancels, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(speech.cancels, 1);
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.textContaining('when you left the app'), findsOneWidget);
    expect(speech.listened, hasLength(1));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(speech.listened, hasLength(2));
    expect(find.text('Listening…'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('voice-cancel')));
    await tester.pumpAndSettle();
    await unmountBuddy(tester, h);
  });
}
