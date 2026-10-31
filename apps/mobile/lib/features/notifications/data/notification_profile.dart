import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_profile.g.dart';

/// The open profile's key, for tagging its notifications (A40 review 1):
/// re-read on every profile switch (sign-in, sign-out, account deletion),
/// like the pending-scan store. `local` before any switch.
@riverpod
Future<String> notificationProfileKey(Ref ref) async {
  ref.watch(profileGenerationProvider);
  final selected = ref.watch(profileKeyProvider);
  final resolve = ref.watch(activeProfileResolverProvider);
  return selected ?? await resolve?.call() ?? 'local';
}
