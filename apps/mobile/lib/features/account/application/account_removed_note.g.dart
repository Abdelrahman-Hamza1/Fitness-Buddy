// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_removed_note.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The one-time note on the new guest's Today after a deletion (A35 D19,
/// #241): what was removed, or null. Read again on every profile switch
/// (a deletion ends with one); it shows only on the guest profile the
/// journaled removal switched to, is cleared as it is read, and so shows
/// in this run until dismissed and never again.

@ProviderFor(AccountRemovedNote)
final accountRemovedNoteProvider = AccountRemovedNoteProvider._();

/// The one-time note on the new guest's Today after a deletion (A35 D19,
/// #241): what was removed, or null. Read again on every profile switch
/// (a deletion ends with one); it shows only on the guest profile the
/// journaled removal switched to, is cleared as it is read, and so shows
/// in this run until dismissed and never again.
final class AccountRemovedNoteProvider
    extends $AsyncNotifierProvider<AccountRemovedNote, AccountRemovedKind?> {
  /// The one-time note on the new guest's Today after a deletion (A35 D19,
  /// #241): what was removed, or null. Read again on every profile switch
  /// (a deletion ends with one); it shows only on the guest profile the
  /// journaled removal switched to, is cleared as it is read, and so shows
  /// in this run until dismissed and never again.
  AccountRemovedNoteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountRemovedNoteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountRemovedNoteHash();

  @$internal
  @override
  AccountRemovedNote create() => AccountRemovedNote();
}

String _$accountRemovedNoteHash() =>
    r'797295e11df8c52e5e6142d4e95d66a1c1a707dd';

/// The one-time note on the new guest's Today after a deletion (A35 D19,
/// #241): what was removed, or null. Read again on every profile switch
/// (a deletion ends with one); it shows only on the guest profile the
/// journaled removal switched to, is cleared as it is read, and so shows
/// in this run until dismissed and never again.

abstract class _$AccountRemovedNote
    extends $AsyncNotifier<AccountRemovedKind?> {
  FutureOr<AccountRemovedKind?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AccountRemovedKind?>, AccountRemovedKind?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AccountRemovedKind?>, AccountRemovedKind?>,
              AsyncValue<AccountRemovedKind?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
