import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/account/application/delete_account_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../today/presentation/support/today_support.dart' show phoneApp;

final class _Recording extends DeleteAccountController {
  new([this.start = DeletePhase.ready]);

  final DeletePhase start;
  final List<bool> deletes = [];

  @override
  DeletePhase build() => start;

  @override
  Future<void> delete({required bool guest}) async => deletes.add(guest);
}

void main() {
  // covers: AC-031
  testWidgets('explain → confirm → delete (signed in)', (tester) async {
    final recording = _Recording();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusProvider.overrideWith(
            (ref) async => AccountStatus.signedIn,
          ),
          deleteAccountControllerProvider.overrideWith(() => recording),
        ],
        child: phoneApp(const DeleteAccountScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-confirm')));
    await tester.pumpAndSettle();
    expect(recording.deletes, [false]);
  });

  testWidgets('A65 m12 delete is a destructive button, busy and disabled '
      'while deleting', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusProvider.overrideWith(
            (ref) async => AccountStatus.signedIn,
          ),
          deleteAccountControllerProvider.overrideWith(
            () => _Recording(DeletePhase.deleting),
          ),
        ],
        child: phoneApp(const DeleteAccountScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    final button = tester.widget<FbButton>(
      find.byKey(const ValueKey('delete-continue')),
    );
    expect(button.busy, isTrue);
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
