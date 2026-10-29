import 'dart:async';

import 'package:fb_mobile/core/catalog/catalog_models.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/settings/application/settings_actions.dart';
import 'package:fb_mobile/features/settings/application/settings_providers.dart';
import 'package:fb_mobile/features/settings/presentation/city_search_list.dart';
import 'package:fb_mobile/features/settings/presentation/settings_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The city picker (LC-033, A10 D7): a search-first list over the pack's
/// cities, found by their English or Arabic name, offline. Nothing typed
/// shows the current city (checked) and suggested cities; a tap sets the city
/// with Undo and goes back. There is no default city: the Me row says "Not
/// set" until one is chosen.
class CityPickerScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  ConsumerState<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends ConsumerState<CityPickerScreen> {
  /// A write is in flight: the choices are off until it ends.
  bool _saving = false;

  Future<void> _choose(CatalogCity city) async {
    if (_saving) return;
    setState(() => _saving = true);
    final host = Navigator.of(context, rootNavigator: true).context;
    final navigator = ref.read(appNavigatorProvider);
    final SettingsOutcome outcome;
    try {
      outcome = await ref.read(settingsActionsProvider).setCity(city.id);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    // Close only a picker that is still the screen on top: a late answer
    // never pops whatever the user has gone to since. A refused change keeps
    // the picker open, with its reason; a duplicate in flight ends nothing.
    if (outcome is SettingsDone || outcome is SettingsUnchanged) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        navigator.pop();
      }
    }
    if (!host.mounted) return;
    reportSettingsOutcome(
      host,
      outcome,
      () => host.l10n.settingsCitySet(cityLabel(host.l10n, city)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentId = ref.watch(cityIdProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cityPickerTitle)),
      body: CitySearchList(
        currentId: currentId,
        onChoose: _saving ? null : (city) => unawaited(_choose(city)),
      ),
    );
  }
}
