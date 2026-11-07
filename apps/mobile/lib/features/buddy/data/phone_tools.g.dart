// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_tools.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's phone tools.

@ProviderFor(phoneTools)
final phoneToolsProvider = PhoneToolsProvider._();

/// The app's phone tools.

final class PhoneToolsProvider
    extends $FunctionalProvider<PhoneTools, PhoneTools, PhoneTools>
    with $Provider<PhoneTools> {
  /// The app's phone tools.
  PhoneToolsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'phoneToolsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$phoneToolsHash();

  @$internal
  @override
  $ProviderElement<PhoneTools> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhoneTools create(Ref ref) {
    return phoneTools(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhoneTools value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhoneTools>(value),
    );
  }
}

String _$phoneToolsHash() => r'66e56ffd6c06039a5731e074c31f64f4e326b295';
