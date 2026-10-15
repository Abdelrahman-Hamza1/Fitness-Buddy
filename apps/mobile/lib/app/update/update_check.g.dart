// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_check.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// View model of the update screen's "Check again" (S06 plan D10, A1).

@ProviderFor(UpdateCheck)
final updateCheckProvider = UpdateCheckProvider._();

/// View model of the update screen's "Check again" (S06 plan D10, A1).
final class UpdateCheckProvider
    extends $NotifierProvider<UpdateCheck, UpdateCheckStatus> {
  /// View model of the update screen's "Check again" (S06 plan D10, A1).
  UpdateCheckProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateCheckProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateCheckHash();

  @$internal
  @override
  UpdateCheck create() => UpdateCheck();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateCheckStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateCheckStatus>(value),
    );
  }
}

String _$updateCheckHash() => r'21ffebecd5f4af103ce34b2dc59cb3ec279a6834';

/// View model of the update screen's "Check again" (S06 plan D10, A1).

abstract class _$UpdateCheck extends $Notifier<UpdateCheckStatus> {
  UpdateCheckStatus build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UpdateCheckStatus, UpdateCheckStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UpdateCheckStatus, UpdateCheckStatus>,
              UpdateCheckStatus,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
