import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/settings/application/city_search.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The offline city search (LC-033, A10 D7): a search field over the pack's
/// cities, found by their English or Arabic name. Nothing typed shows the
/// current city (checked) and suggested cities. A tap reports the city to
/// [onChoose]; what happens then is the caller's (Me's picker sets the
/// setting with Undo; setup's sheet returns the pick to its draft, A13 D10).
///
/// With [expand] the results scroll on their own (a screen body: give it the
/// remaining height); without, they are a column for a sheet's scroll view.
class CitySearchList extends ConsumerStatefulWidget {
  /// Creates the search.
  const new({
    required this.currentId,
    required this.onChoose,
    this.expand = true,
    this.autofocus = true,
    super.key,
  });

  /// The chosen city's identity, checked in the list; null for none.
  final String? currentId;

  /// Called with the tapped city; null turns the rows off (a save in
  /// flight).
  final ValueChanged<CatalogCity>? onChoose;

  /// Whether the results scroll on their own.
  final bool expand;

  /// Whether the search field takes the keyboard when shown.
  final bool autofocus;

  @override
  ConsumerState<CitySearchList> createState() => _CitySearchListState();
}

class _CitySearchListState extends ConsumerState<CitySearchList> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final search = ref.watch(citySearchProvider);
    final pad = widget.expand
        ? const EdgeInsetsDirectional.symmetric(
            horizontal: FbSpace.s4,
            vertical: FbSpace.s2,
          )
        : const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s2);
    final results = switch (search) {
      AsyncData(:final value) => _Results(
        search: value,
        query: _controller.text,
        currentId: widget.currentId,
        onChoose: widget.onChoose,
        expand: widget.expand,
      ),
      AsyncError() => Padding(
        padding: pad,
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
      // Expanded (the picker screen) the rows scroll: with the keyboard up
      // on a 320 x 640 phone they don't fit (nightly android-it). In the
      // onboarding sheet the plain column sizes the sheet.
      _ when widget.expand => SingleChildScrollView(
        padding: pad,
        physics: const NeverScrollableScrollPhysics(),
        child: const _Skeleton(),
      ),
      _ => Padding(padding: pad, child: const _Skeleton()),
    };
    return Column(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: pad,
          child: FbSearchField(
            controller: _controller,
            hint: l10n.cityPickerSearchHint,
            autofocus: widget.autofocus,
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (widget.expand) Expanded(child: results) else results,
      ],
    );
  }
}

/// Placeholder rows while the cities load (UX-051).
class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
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
    required this.expand,
  });

  final CitySearch search;
  final String query;
  final String? currentId;
  final ValueChanged<CatalogCity>? onChoose;
  final bool expand;

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
    final rows = [
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
    ];
    return expand
        ? ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: rows,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
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
