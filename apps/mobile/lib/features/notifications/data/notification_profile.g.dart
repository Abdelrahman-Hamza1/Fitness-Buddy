// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_profile.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The open profile's key, for tagging its notifications (A40 review 1):
/// re-read on every profile switch (sign-in, sign-out, account deletion),
/// like the pending-scan store. `local` before any switch.

@ProviderFor(notificationProfileKey)
final notificationProfileKeyProvider = NotificationProfileKeyProvider._();

/// The open profile's key, for tagging its notifications (A40 review 1):
/// re-read on every profile switch (sign-in, sign-out, account deletion),
/// like the pending-scan store. `local` before any switch.

final class NotificationProfileKeyProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The open profile's key, for tagging its notifications (A40 review 1):
  /// re-read on every profile switch (sign-in, sign-out, account deletion),
  /// like the pending-scan store. `local` before any switch.
  NotificationProfileKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationProfileKeyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationProfileKeyHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return notificationProfileKey(ref);
  }
}

String _$notificationProfileKeyHash() =>
    r'd9a9a40485647c40260722ced154bd3255e3705c';
