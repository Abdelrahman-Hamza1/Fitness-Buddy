// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'undo_stack.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [UndoStack]. A02's snackbar undoes with
/// `ref.read(undoStackProvider).undo(entry.id)`.

@ProviderFor(undoStack)
final undoStackProvider = UndoStackProvider._();

/// The app's [UndoStack]. A02's snackbar undoes with
/// `ref.read(undoStackProvider).undo(entry.id)`.

final class UndoStackProvider
    extends $FunctionalProvider<UndoStack, UndoStack, UndoStack>
    with $Provider<UndoStack> {
  /// The app's [UndoStack]. A02's snackbar undoes with
  /// `ref.read(undoStackProvider).undo(entry.id)`.
  UndoStackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'undoStackProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$undoStackHash();

  @$internal
  @override
  $ProviderElement<UndoStack> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UndoStack create(Ref ref) {
    return undoStack(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UndoStack value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UndoStack>(value),
    );
  }
}

String _$undoStackHash() => r'fb7d32d9ae2bf2a6dc494d3d0c71c1458fef7bd7';

/// The newest entry that can still be undone, `null` once it expires: what
/// the undo snackbar shows (A02, A08).

@ProviderFor(latestUndo)
final latestUndoProvider = LatestUndoProvider._();

/// The newest entry that can still be undone, `null` once it expires: what
/// the undo snackbar shows (A02, A08).

final class LatestUndoProvider
    extends
        $FunctionalProvider<
          AsyncValue<UndoEntry?>,
          UndoEntry?,
          Stream<UndoEntry?>
        >
    with $FutureModifier<UndoEntry?>, $StreamProvider<UndoEntry?> {
  /// The newest entry that can still be undone, `null` once it expires: what
  /// the undo snackbar shows (A02, A08).
  LatestUndoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'latestUndoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$latestUndoHash();

  @$internal
  @override
  $StreamProviderElement<UndoEntry?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<UndoEntry?> create(Ref ref) {
    return latestUndo(ref);
  }
}

String _$latestUndoHash() => r'2e6f18400c0ce82c2202f238324625ee53744164';
