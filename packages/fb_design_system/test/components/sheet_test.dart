import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

/// An app shell: a scaffold whose body is a nested (tab) navigator, like the
/// app's go_router shell. Its snackbars paint above everything in its body.
class _Shell extends StatelessWidget {
  const new({required this.saved});

  final List<String> saved;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => showFbUndoSnackBar(
                  context,
                  message: 'Added Banana',
                  onUndo: () {},
                ),
                child: const Text('add'),
              ),
              TextButton(
                onPressed: () => showFbSheet<void>(
                  context,
                  builder: (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 300),
                      FbButton.primary(
                        label: 'Save',
                        expand: true,
                        onPressed: () => saved.add('save'),
                      ),
                    ],
                  ),
                ),
                child: const Text('open'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('UX-030 a sheet opened inside the tab navigator sits above the '
      "shell's Undo snackbar, so its bottom button stays tappable", (
    tester,
  ) async {
    final saved = <String>[];
    await pumpFb(tester, _Shell(saved: saved), width: 320, height: 640);
    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
    expect(find.text('Added Banana'), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FbButton, 'Save');
    // The snackbar is still up; the sheet's button must win the hit test.
    expect(find.text('Added Banana'), findsOneWidget);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(saved, ['save']);
  });
}
