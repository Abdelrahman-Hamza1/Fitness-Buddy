import 'dart:async';
import 'dart:isolate';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/foods/application/food_choice.dart';
import 'package:fb_mobile/features/foods/application/food_search_row.dart';
import 'package:fb_mobile/features/foods/data/food_catalog_repository.dart';
import 'package:fb_text/fb_text.dart';

/// Complete local result. Fuzzy readiness never blocks search.
final class FoodSearchResults {
  /// Creates this structured value.
  const new({
    required this.rows,
    required this.packReady,
    this.carried,
    this.hasGood = false,
  });

  /// Ranked, de-duplicated foods for this query.
  final List<FoodSearchRow> rows;

  /// Whether a readable catalog pack is attached.
  final bool packReady;

  /// Quantity hypothesis accepted only after the original name fails.
  final ParsedAmount? carried;

  /// Whether the unsplit query has a good-band match.
  final bool hasGood;
}

FuzzyIndex _buildIndex(List<String> words) => FuzzyIndex.build(words);

/// Offline orchestration. History and aliases are prepared on emissions,
/// outside per-keystroke matching. Refreshes and isolate builds keep only
/// the newest pending input.
final class FoodSearchService {
  /// Creates this structured value.
  new(this.repository, {this.onIndexCounts}) {
    _initializing = updateHistory([]);
    _packSub = repository.packChanges.listen((_) {
      unawaited(updateHistory(_latestHistory));
    });
  }

  /// Offline catalog read port.
  final FoodCatalogRepository repository;

  /// Content-free index counts after a completed background build.
  final void Function(int words, int deletionKeys, {required bool distanceTwo})?
  onIndexCounts;
  late final Future<void> _initializing;
  late final StreamSubscription<void> _packSub;
  List<PersonalFood> _latestPersonal = [];
  Map<String, PersonalFood> _personal = {};

  /// Latest fully prepared live definitions.
  List<PersonalFood> get personalFoods => List.unmodifiable(_personal.values);

  /// Shares the history refresh queue, so neither input can publish stale work.
  Future<void> updatePersonalFoods(List<PersonalFood> foods) {
    _latestPersonal = List.of(foods);
    return updateHistory(_latestHistory);
  }

  List<FoodHistoryItem> _latestHistory = [];
  List<FoodHistoryItem> _history = [];

  /// Latest fully prepared live food history.
  List<FoodHistoryItem> get history => List.unmodifiable(_history);
  final _changes = StreamController<void>.broadcast();

  /// Refresh notifications for history, pack and fuzzy readiness.
  Stream<void> get changes => _changes.stream;
  Map<String, List<String>> _historyKeys = {};
  Map<String, CatalogFood> _historyFoods = {};
  int? _version;

  /// Whether a readable catalog pack is attached.
  bool get packReady => _version != null;
  Set<String> _words = {};
  List<String> _packKeys = [];
  Set<String> _historyCatalogIds = {};
  Map<String, List<String>> _aliases = {};
  Map<String, FoodNames> _snapshotNames = {};
  bool _prepared = false;
  FuzzyIndex? _index;

  /// Most recent completed background index; null until ready.
  FuzzyIndex? get fuzzyIndex => _index;
  List<String>? _pendingWords;
  Future<void>? _building;

  /// Completes after current and pending index builds (for gates).
  Future<void> get indexReady => _building ?? Future.value();
  List<FoodHistoryItem>? _pendingHistory;
  Future<void>? _refreshing;
  bool _disposed = false;

  /// Replaces queued emissions instead of appending work to drift's queue.
  Future<void> updateHistory(List<FoodHistoryItem> history) {
    _latestHistory = List.of(history);
    _pendingHistory = _latestHistory;
    return _refreshing ??= _refreshLoop().whenComplete(
      () => _refreshing = null,
    );
  }

  Future<void> _refreshLoop() async {
    while (_pendingHistory != null) {
      final personal = {for (final f in _latestPersonal) f.id: f};
      final next = _pendingHistory!
          .where(
            (h) =>
                h.food.ref.kind != FoodRefKind.personal ||
                personal.containsKey(h.food.ref.id),
          )
          .toList();
      _pendingHistory = null;
      final version = await repository.packVersion();
      final packChanged = !_prepared || version != _version;
      final packKeys = packChanged
          ? await repository.vocabularyKeys()
          : _packKeys;
      var historyFoods = _historyFoods;
      var historyAliases = _aliases;
      final ids = [
        for (final h in next)
          if (h.food.ref.kind == FoodRefKind.catalog) h.food.ref.id!,
      ];
      final idSet = ids.toSet();
      final metadataChanged =
          packChanged ||
          idSet.length != _historyCatalogIds.length ||
          !_historyCatalogIds.containsAll(idSet);
      if (metadataChanged) {
        final foods = await repository.foodsByIds(ids);
        final targets = {
          ...ids,
          for (final list in foods.values)
            for (final f in list)
              if (f.dishId != null) f.dishId!,
        };
        final aliases = await repository.namesForTargets(targets);
        if (_pendingHistory != null || _disposed) continue;
        historyFoods = {
          for (final list in foods.values)
            for (final f in list) f.id: f,
        };
        historyAliases = {};
        for (final alias in aliases) {
          historyAliases.putIfAbsent(alias.targetId, () => []).add(alias.key);
        }
      }
      if (_pendingHistory != null || _disposed) continue;
      var vocabularyChanged =
          personal.length != _personal.length ||
          personal.entries.any((e) => _personal[e.key] != e.value);
      vocabularyChanged =
          vocabularyChanged ||
          metadataChanged ||
          next.length != _snapshotNames.length;
      final keys = <String, List<String>>{};
      final snapshots = <String, FoodNames>{};
      for (final h in next) {
        final id = _identity(h.food.ref);
        final names = personal[h.food.ref.id]?.names ?? h.food.names;
        snapshots[id] = names;
        if (h.food.ref.kind == FoodRefKind.personal) {
          keys[id] = _personalKeys(personal[h.food.ref.id]!);
        } else if (!metadataChanged && _snapshotNames[id] == names) {
          keys[id] = _historyKeys[id]!;
        } else {
          vocabularyChanged = true;
          keys[id] = [
            normalizeKey(names.en),
            if (names.ar case final ar?) normalizeKey(ar),
            ...?historyAliases[h.food.ref.id],
            ...?historyAliases[historyFoods[h.food.ref.id]?.dishId],
          ];
        }
      }
      // Publish the pack identity with all derived metadata, only after the
      // last await and supersession check. A queued history emission retries.
      _personal = personal;
      _version = version;
      _packKeys = packKeys;
      _historyFoods = historyFoods;
      _aliases = historyAliases;
      _historyCatalogIds = idSet;
      _snapshotNames = snapshots;
      _historyKeys = keys;
      _prepared = true;
      _history = next;
      if (vocabularyChanged) {
        final words = {
          for (final key in [
            ..._packKeys,
            for (final f in _personal.values) ..._personalKeys(f),
            ..._historyKeys.values.expand((k) => k),
          ])
            ...key.split(' ').where((w) => w.isNotEmpty),
        };
        if (words.length != _words.length || !_words.containsAll(words)) {
          _words = words;
          _pendingWords = words.toList();
          _building ??= _buildLoop().whenComplete(() => _building = null);
        }
      }
      if (!_changes.isClosed) _changes.add(null);
    }
  }

  Future<void> _buildLoop() async {
    while (_pendingWords != null) {
      final words = _pendingWords!;
      _pendingWords = null;
      // Capture only the words, never a service/database/subscription.
      final built = await Isolate.run(() => _buildIndex(words));
      if (_pendingWords != null || _disposed) continue;
      _index = built;
      onIndexCounts?.call(
        words.length,
        built.deletionKeyCount,
        distanceTwo: built.distanceTwoEnabled,
      );
      if (!_changes.isClosed) _changes.add(null);
    }
  }

  /// Finds offline foods, preserving numeric names before quantity splitting.
  /// [system] picks the default portion shown on each row, the same one the
  /// amount sheet opens with.
  Future<FoodSearchResults> search(
    String text, {
    UnitSystem system = UnitSystem.metric,
  }) async {
    await _initializing;
    await _refreshing;
    final parsed = parseQuantity(text);
    if (parsed != null && parsed.hasQuantity) {
      final original = await _searchKey(normalizeKey(text), system: system);
      if (original.hasGood) return original;
      final carried = ParsedAmount(parsed.amount, parsed.unitCode);
      return await _searchKey(
        normalizeKey(parsed.rest),
        carried: carried,
        system: system,
      );
    }
    return await _searchKey(normalizeKey(text), system: system);
  }

  /// Whether the query requests recent foods.
  Future<FoodSearchResults> recent({UnitSystem system = UnitSystem.metric}) =>
      search('', system: system);

  Future<FoodSearchResults> _searchKey(
    String key, {
    required UnitSystem system,
    ParsedAmount? carried,
  }) async {
    if (key.isEmpty) {
      final candidates = <SearchCandidate<FoodSearchRow>>[];
      for (final h in _history) {
        final choice = _choice(h);
        final row = FoodSearchRow(
          choice: choice,
          tier: _tier(h),
          system: system,
        );
        candidates.add(
          SearchCandidate(
            keys: _keys(choice),
            // Recent rows are ordered solely by recency, after merging dishes.
            tier: SourceTier.history,
            strength: MatchStrength.exact,
            lastUsedHlc: h.lastUsedHlc,
            nameLength: row.nameEn.length,
            id: row.identity,
            payload: row,
          ),
        );
      }
      return FoodSearchResults(
        packReady: packReady,
        rows: FoodSearchRanker.rank(candidates, limit: 20),
      );
    }
    final index = _index;
    final tokens = key.split(' ');
    final corrections = {
      if (index != null)
        for (final token in tokens.toSet()) token: index.corrections(token),
    };
    MatchStrength? match(Iterable<String> keys) {
      MatchStrength? best;
      for (final name in keys) {
        final strength = NameMatcher.match(
          key,
          tokens,
          name,
          corrections: corrections,
        );
        if (strength != null && (best == null || strength.index > best.index)) {
          best = strength;
        }
      }
      return best;
    }

    final names = await repository.candidateNames(
      CandidateQuery(key, corrections: corrections),
    );
    final best = <String, MatchStrength>{};
    final hits = <String, int>{};
    final lengths = <String, int>{};
    for (final name in names) {
      final strength = match([name.key]);
      if (strength == null) continue;
      final id = name.targetId;
      if (best[id] == null || strength.index > best[id]!.index) {
        best[id] = strength;
      }
      if ((hits[id] ?? -1) < name.wordHits) hits[id] = name.wordHits;
      if ((lengths[id] ?? 1 << 30) > name.key.length) {
        lengths[id] = name.key.length;
      }
    }
    final matchedHistory = <String, MatchStrength>{};
    for (final h in _history) {
      final id = _identity(h.food.ref);
      final strength = match(_historyKeys[id] ?? []);
      if (strength != null) matchedHistory[id] = strength;
    }
    final ordered = best.keys.toList()
      ..sort((a, b) {
        var c = best[b]!.index.compareTo(best[a]!.index);
        if (c == 0) c = hits[b]!.compareTo(hits[a]!);
        if (c == 0) c = lengths[a]!.compareTo(lengths[b]!);
        return c == 0 ? a.compareTo(b) : c;
      });
    final selected = <String>{
      ...ordered.where((id) => best[id]!.index >= MatchStrength.prefix.index),
      ...ordered.take(60),
    };
    final foods = await repository.foodsByIds(selected);
    final candidates = <SearchCandidate<FoodSearchRow>>[];
    final historyById = {for (final h in _history) _identity(h.food.ref): h};
    void add(FoodChoice choice, MatchStrength strength, SourceTier tier) {
      final f = choice.catalogFood;
      final h = choice.lastUsed;
      final row = FoodSearchRow(
        choice: choice,
        tier: tier,
        parsed: carried,
        system: system,
      );
      candidates.add(
        SearchCandidate(
          keys: _keys(choice),
          tier: tier,
          strength: strength,
          uses: h?.uses ?? 0,
          lastUsedHlc: h?.lastUsedHlc,
          nameLength: row.nameEn.runes.length,
          id: row.identity,
          payload: row,
          isDefaultVariant: f?.isDefaultVariant ?? false,
        ),
      );
    }

    for (final f in _personal.values) {
      final strength = match(_personalKeys(f));
      if (strength != null) {
        add(
          personalChoice(f, history: historyById['personal:${f.id}']),
          strength,
          SourceTier.personal,
        );
      }
    }
    final seen = <String>{};
    for (final id in selected) {
      for (final f in foods[id] ?? <CatalogFood>[]) {
        if (!seen.add(f.id)) continue;
        final h = historyById['catalog:${f.id}'];
        final historyMatch = matchedHistory['catalog:${f.id}'];
        final strength =
            historyMatch != null && historyMatch.index > best[id]!.index
            ? historyMatch
            : best[id]!;
        add(
          catalogChoice(f, history: h),
          strength,
          h == null ? _catalogTier(f) : _tier(h),
        );
      }
    }
    for (final h in _history) {
      final strength = matchedHistory[_identity(h.food.ref)];
      if (strength != null &&
          h.food.ref.kind != FoodRefKind.personal &&
          (h.food.ref.kind != FoodRefKind.catalog ||
              !seen.contains(h.food.ref.id))) {
        add(_choice(h), strength, _tier(h));
      }
    }
    return FoodSearchResults(
      packReady: packReady,
      carried: carried,
      rows: FoodSearchRanker.rank(candidates),
      hasGood:
          best.values.any((s) => s.isGood) ||
          matchedHistory.values.any((s) => s.isGood) ||
          _personal.values.any((f) => match(_personalKeys(f))?.isGood ?? false),
    );
  }

  Set<String> _keys(FoodChoice choice) {
    final f = choice.catalogFood;
    final p = choice.personalFood;
    final brand = p?.brand == null ? '-' : identityKey(p!.brand!);
    return {
      if (p != null) ...[
        'name:${identityKey(p.names.en)}|${p.state.code}|$brand',
        if (p.names.ar case final ar?)
          'name:${identityKey(ar)}|${p.state.code}|$brand',
      ],
      _identity(choice.ref),
      if (f?.dishId case final dish?) 'dish:$dish',
      if (f != null) ...[
        'name:${identityKey(f.nameEn)}|${f.state.code}|-',
        if (f.nameAr case final ar?)
          'name:${identityKey(ar)}|${f.state.code}|-',
      ],
    };
  }

  List<String> _personalKeys(PersonalFood f) => [
    normalizeKey(f.names.en),
    if (f.names.ar case final ar?) normalizeKey(ar),
    ...f.aliases.map(normalizeKey),
  ];

  FoodChoice _choice(FoodHistoryItem h) {
    if (h.food.ref.kind == FoodRefKind.personal) {
      return personalChoice(_personal[h.food.ref.id]!, history: h);
    }
    final food = h.food.ref.kind == FoodRefKind.catalog
        ? _historyFoods[h.food.ref.id]
        : null;
    return food == null ? historyChoice(h) : catalogChoice(food, history: h);
  }

  static String _identity(FoodRef ref) => '${ref.kind.code}:${ref.id}';
  static SourceTier _tier(FoodHistoryItem h) =>
      h.food.ref.kind == FoodRefKind.personal
      ? SourceTier.personal
      : SourceTier.history;
  static SourceTier _catalogTier(CatalogFood f) =>
      f.badge == CatalogBadge.reference
      ? SourceTier.reference
      : SourceTier.database;

  /// Stops notifications and discards unfinished refresh results.
  void dispose() {
    _disposed = true;
    unawaited(_packSub.cancel());
    unawaited(_changes.close());
  }
}
