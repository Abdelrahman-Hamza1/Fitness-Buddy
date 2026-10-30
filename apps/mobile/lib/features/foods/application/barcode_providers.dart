import 'dart:async';

import 'package:fb_domain/fb_domain.dart';

import 'package:fb_mobile/core/catalog/barcode_coverage.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/foods/application/barcode_lookup.dart';
import 'package:fb_mobile/features/foods/application/food_choice.dart';
import 'package:fb_mobile/features/foods/application/foods_providers.dart';
import 'package:fb_mobile/features/foods/data/barcode_api.dart';
import 'package:fb_mobile/features/foods/data/pending_scans_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:fb_mobile/features/foods/data/pending_scans_store.dart'
    show PendingScan, PendingScanState;

part 'barcode_providers.g.dart';

/// Scanned products not saved yet, by their reserved personal ID (A28a D8),
/// so the food sheet can load them; same idea as A24's online-food cache.
/// In memory, bounded; a logged product is a real personal food afterwards.
final class ScannedFoodRegistry {
  final _choices = <String, FoodChoice>{};

  /// Remembers [choice] under its ID (oldest dropped past 20).
  void put(FoodChoice choice) {
    _choices
      ..remove(choice.ref.id)
      ..[choice.ref.id!] = choice;
    while (_choices.length > 20) {
      _choices.remove(_choices.keys.first);
    }
  }

  /// The scanned choice with [id], if any.
  FoodChoice? operator [](String id) => _choices[id];

  /// Forgets [id] (after it was logged).
  void remove(String id) => _choices.remove(id);
}

/// Whether the scanner opens the camera (A28a D13). On in the app; widget
/// tests switch it off (no platform camera there) and type the code.
@Riverpod(keepAlive: true)
bool barcodeCameraEnabled(Ref ref) => true;

/// The registry for this app run.
@Riverpod(keepAlive: true)
ScannedFoodRegistry scannedFoodRegistry(Ref ref) => ScannedFoodRegistry();

/// The barcode chain over the app's repositories and the server.
@riverpod
BarcodeLookup barcodeLookup(Ref ref) {
  final ids = ref.watch(idGeneratorProvider);
  final catalog = ref.watch(foodCatalogRepositoryProvider);
  final personal = ref.watch(personalFoodRepositoryProvider);
  final api = ref.watch(barcodeApiProvider);
  final coverage = ref.watch(barcodeCoverageProvider);
  return BarcodeLookup(
    personalByBarcode: personal.byBarcode,
    packByBarcode: catalog.byBarcode,
    server: api.lookup,
    newId: ids.next,
    count: coverage.add,
  );
}

/// One-shot handoff of a scan's prefill to the new-food form (A28a D9);
/// like the search's name prefill, private data never enters a route.
@Riverpod(keepAlive: true)
class ScanFoodPrefill extends _$ScanFoodPrefill {
  @override
  ScanPrefill? build() => null;

  /// Sets the prefill for the next form.
  // A command on the notifier, like NewFoodPrefill.put.
  // ignore: use_setters_to_change_properties
  void put(ScanPrefill prefill) => state = prefill;

  /// Consumes the prefill; later forms start clean.
  ScanPrefill? take() {
    final value = state;
    state = null;
    return value;
  }
}

/// Scans waiting for a later lookup (A28a D10, OF-02): at most [maxScans],
/// dropped after [maxAge], one list per local profile (review fix 1: the
/// store follows profile switches; work started for an older profile never
/// writes into the new one). [process] looks the waiting ones up again; it
/// runs when the scanner opens, when the app comes back to the front and
/// after a successful lookup, never on the startup path. A scan leaves the
/// list only when it was logged, saved as your food, or dismissed (review
/// fix 3).
@Riverpod(keepAlive: true)
class PendingScans extends _$PendingScans {
  /// The most scans kept.
  static const maxScans = 20;

  /// How long a scan is kept.
  static const maxAge = Duration(days: 14);

  PendingScansStore? _store;

  /// Bumped synchronously at every rebuild (a profile switch): work that
  /// started under an older epoch never publishes (review fix 1; the
  /// notifier itself survives rebuilds, so `ref.mounted` can't tell).
  int _epoch = 0;
  int? _processingEpoch;

  @override
  Future<List<PendingScan>> build() async {
    final epoch = ++_epoch;
    _store = null;
    final store = await ref.watch(pendingScansStoreProvider.future);
    if (epoch == _epoch) _store = store;
    return _fresh(await store.read());
  }

  List<PendingScan> _fresh(List<PendingScan> scans) {
    final now = ref.read(clockProvider).nowUtc().millisecondsSinceEpoch;
    final kept = [
      for (final s in scans)
        if (now - s.scannedAtMs < maxAge.inMilliseconds) s,
    ];
    return kept.length > maxScans ? kept.sublist(kept.length - maxScans) : kept;
  }

  /// The list of [epoch] and its store, or null when the profile changed
  /// before or while it loaded.
  Future<(PendingScansStore, List<PendingScan>)?> _current(int epoch) async {
    if (epoch != _epoch) return null;
    final scans = await future;
    final store = _store;
    if (epoch != _epoch || store == null) return null;
    return (store, scans);
  }

  /// Writes [scans] for [epoch], unless the profile changed meanwhile.
  Future<void> _save(int epoch, List<PendingScan> scans) async {
    final store = _store;
    if (!ref.mounted || epoch != _epoch || store == null) return;
    final fresh = _fresh(scans);
    state = AsyncData(fresh);
    await store.write(fresh);
  }

  /// Keeps [code] for a later lookup (once).
  Future<void> add(String code) async {
    final epoch = _epoch;
    final current = await _current(epoch);
    if (current == null) return;
    final (_, scans) = current;
    if (scans.any((s) => s.code == code)) return;
    await _save(epoch, [
      ...scans,
      PendingScan(
        code: code,
        scannedAtMs: ref.read(clockProvider).nowUtc().millisecondsSinceEpoch,
      ),
    ]);
  }

  /// Records a later answer for [code] if it is in the list (it stays until
  /// logged, saved or dismissed).
  Future<void> resolve(
    String code,
    PendingScanState next, {
    String? name,
    bool fromOff = false,
  }) async {
    final epoch = _epoch;
    final current = await _current(epoch);
    if (current == null) return;
    final (_, scans) = current;
    if (!scans.any((s) => s.code == code)) return;
    await _save(epoch, [
      for (final s in scans)
        if (s.code == code)
          s.withState(next, name: name, fromOff: fromOff)
        else
          s,
    ]);
  }

  /// Forgets [code] (logged or dismissed).
  Future<void> remove(String code) => removeAll([code]);

  /// Forgets every code among [barcodes], compared in GTIN-normalized form
  /// (a personal food was saved with them).
  Future<void> removeAll(Iterable<String> barcodes) async {
    final epoch = _epoch;
    final codes = {for (final b in barcodes) Gtin.normalize(b) ?? b};
    final current = await _current(epoch);
    if (current == null) return;
    final (_, scans) = current;
    if (!scans.any((s) => codes.contains(s.code))) return;
    await _save(epoch, [
      for (final s in scans)
        if (!codes.contains(s.code)) s,
    ]);
  }

  /// Looks every waiting scan up again; stops at the first one that still
  /// can't run (offline), or as soon as the profile changed (checked after
  /// every await, before anything is published). A code that became one of
  /// your foods is dropped.
  Future<void> process(BarcodeLookup lookup) async {
    final epoch = _epoch;
    if (_processingEpoch == epoch) return;
    _processingEpoch = epoch;
    try {
      final initial = await _current(epoch);
      if (initial == null) return;
      for (final scan in initial.$2) {
        if (scan.state != PendingScanState.waiting) continue;
        final outcome = await lookup.lookup(scan.code);
        final current = await _current(epoch);
        if (current == null) return;
        final (_, scans) = current;
        switch (outcome) {
          case BarcodeWaiting():
            return;
          case BarcodeFound(:final choice)
              when choice.personalFood != null && choice.pendingCreate == null:
            await _save(epoch, [
              for (final s in scans)
                if (s.code != scan.code) s,
            ]);
          case BarcodeFound(:final choice, :final product):
            await _replace(
              epoch,
              scans,
              scan,
              PendingScanState.ready,
              choice.names.en,
              fromOff: product.fromOff,
            );
          case BarcodeIncomplete(:final off, :final product):
            await _replace(
              epoch,
              scans,
              scan,
              PendingScanState.ready,
              off.name,
              fromOff: product.fromOff,
            );
          case BarcodeNotFound():
            await _replace(epoch, scans, scan, PendingScanState.notFound, null);
          case BarcodeInvalid():
            await _save(epoch, [
              for (final s in scans)
                if (s.code != scan.code) s,
            ]);
        }
      }
    } finally {
      if (_processingEpoch == epoch) _processingEpoch = null;
    }
  }

  Future<void> _replace(
    int epoch,
    List<PendingScan> scans,
    PendingScan scan,
    PendingScanState next,
    String? name, {
    bool fromOff = false,
  }) => _save(epoch, [
    for (final s in scans)
      if (s.code == scan.code)
        s.withState(next, name: name, fromOff: fromOff)
      else
        s,
  ]);
}

/// Unawaited processing with errors swallowed: a background convenience
/// that must never break the screen that triggers it. [scans] and [lookup]
/// are read only when the work runs.
void processPendingScans(
  PendingScans Function() scans,
  BarcodeLookup Function() lookup,
) => unawaited(
  Future<void>.microtask(() => scans().process(lookup()))
      .catchError((Object _) {}),
);
