// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_cards.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's record cards.

@ProviderFor(recordCards)
final recordCardsProvider = RecordCardsProvider._();

/// The app's record cards.

final class RecordCardsProvider
    extends $FunctionalProvider<RecordCards, RecordCards, RecordCards>
    with $Provider<RecordCards> {
  /// The app's record cards.
  RecordCardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordCardsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordCardsHash();

  @$internal
  @override
  $ProviderElement<RecordCards> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecordCards create(Ref ref) {
    return recordCards(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordCards value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordCards>(value),
    );
  }
}

String _$recordCardsHash() => r'a43bc27f8ded8f44986f3f43dc9730a4b0b1807e';
