import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Food search as a picker over the card (AI-041 swap, AI-042 add; A22b
/// review 3): a sheet with the search field and the offline results; tapping
/// one returns it. Nothing is logged here, and it works offline.
Future<FoodSearchRow?> showBuddyFoodPicker(BuildContext context) =>
    showFbSheet<FoodSearchRow>(
      context,
      title: context.l10n.proposalPickerTitle,
      builder: (context) => const _FoodPicker(),
    );

class _FoodPicker extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_FoodPicker> createState() => _FoodPickerState();
}

class _FoodPickerState extends ConsumerState<_FoodPicker> {
  final _query = TextEditingController();
  List<FoodSearchRow> _rows = const [];
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_search(''));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String text) async {
    final generation = ++_generation;
    final system = ref.read(unitSystemProvider).value ?? UnitSystem.metric;
    final results = await ref
        .read(foodSearchServiceProvider)
        .search(text, system: system);
    // Only the newest query's results are shown.
    if (!mounted || generation != _generation) return;
    setState(() => _rows = results.rows);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        FbSearchField(
          controller: _query,
          hint: l10n.proposalPickerHint,
          autofocus: true,
          onChanged: (text) => unawaited(_search(text)),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.5,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final row in _rows)
                FoodResultRow(
                  key: ValueKey(row.identity),
                  row: row,
                  onTap: () => Navigator.of(context).pop(row),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
