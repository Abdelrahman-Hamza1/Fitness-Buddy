import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/settings/application/city_search.dart';
import 'package:fb_mobile/features/settings/application/settings_actions.dart';
import 'package:fb_mobile/features/settings/application/settings_providers.dart';
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
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    final search = ref.watch(citySearchProvider);
    final currentId = ref.watch(cityIdProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cityPickerTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: FbSpace.s4,
              vertical: FbSpace.s2,
            ),
            child: FbSearchField(
              controller: _controller,
              hint: l10n.cityPickerSearchHint,
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: switch (search) {
              AsyncData(:final value) => _Results(
                search: value,
                query: _controller.text,
                currentId: currentId,
                onChoose: _saving ? null : (city) => unawaited(_choose(city)),
              ),
              AsyncError() => Padding(
                padding: const EdgeInsetsDirectional.all(FbSpace.s4),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: FbInlineBanner(
                    kind: FbInlineBannerKind.error,
                    message: l10n.cityPickerLoadFailed,
                    actionLabel: l10n.cityPickerTryAgain,
                    onAction: () => ref.invalidate(citySearchProvider),
                  ),
                ),
              ),
              _ => const _Skeleton(),
            },
          ),
        ],
      ),
    );
  }
}

/// Placeholder rows while the cities load (UX-051).
class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: FbSpace.s4,
      vertical: FbSpace.s2,
    ),
    children: [
      for (var i = 0; i < 8; i++)
        const Padding(
          padding: EdgeInsetsDirectional.symmetric(vertical: FbSpace.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FbSpace.s2,
            children: [
              FbSkeleton.line(width: 180, height: 16),
              FbSkeleton.line(width: 90),
            ],
          ),
        ),
    ],
  );
}

class _Results extends ConsumerWidget {
  const new({
    required this.search,
    required this.query,
    required this.currentId,
    required this.onChoose,
  });

  final CitySearch search;
  final String query;
  final String? currentId;
  final ValueChanged<CatalogCity>? onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final typed = query.trim().isNotEmpty;
    final results = typed ? search.query(query) : search.suggestions(currentId);
    final isDev = ref.watch(appConfigProvider).flavor == AppFlavor.dev;
    final choose = onChoose;
    if (search.isEmpty) {
      // No pack or an empty list, whatever was typed: say so.
      return Padding(
        padding: const EdgeInsetsDirectional.all(FbSpace.s4),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: FbInlineBanner(
            kind: FbInlineBannerKind.info,
            message: l10n.cityPickerUnavailable,
          ),
        ),
      );
    }
    if (typed && results.isEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.all(FbSpace.s4),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: Text(
            l10n.cityPickerNoMatch,
            style: FbType.body.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // Opt-in location (D-074) arrives with the prayer times (A41).
        if (isDev && !typed)
          FbListRow(
            title: l10n.cityPickerUseLocation,
            subtitle: l10n.cityPickerComingSoon,
          ),
        if (!typed) FbSectionHeader(title: l10n.cityPickerSuggested),
        for (final result in results)
          _CityRow(
            city: result.city,
            selected: result.city.id == currentId,
            onTap: choose == null ? null : () => choose(result.city),
          ),
      ],
    );
  }
}

class _CityRow extends StatelessWidget {
  const new({required this.city, required this.selected, required this.onTap});

  final CatalogCity city;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        child: FbListRow(
          title: cityLabel(l10n, city),
          subtitle: countryLabel(l10n, city.countryCode),
          trailing: selected
              ? const ExcludeSemantics(child: Icon(FbIcons.check))
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
