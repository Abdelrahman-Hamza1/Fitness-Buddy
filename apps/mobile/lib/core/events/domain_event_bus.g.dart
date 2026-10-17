// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_event_bus.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [DomainEventBus]. Consumers subscribe in their own provider and
/// cancel in `ref.onDispose`.

@ProviderFor(domainEventBus)
final domainEventBusProvider = DomainEventBusProvider._();

/// The app's [DomainEventBus]. Consumers subscribe in their own provider and
/// cancel in `ref.onDispose`.

final class DomainEventBusProvider
    extends $FunctionalProvider<DomainEventBus, DomainEventBus, DomainEventBus>
    with $Provider<DomainEventBus> {
  /// The app's [DomainEventBus]. Consumers subscribe in their own provider and
  /// cancel in `ref.onDispose`.
  DomainEventBusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'domainEventBusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$domainEventBusHash();

  @$internal
  @override
  $ProviderElement<DomainEventBus> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DomainEventBus create(Ref ref) {
    return domainEventBus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DomainEventBus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DomainEventBus>(value),
    );
  }
}

String _$domainEventBusHash() => r'04b0d19ac079f23ff2c73078bb7b5d67e626b481';
