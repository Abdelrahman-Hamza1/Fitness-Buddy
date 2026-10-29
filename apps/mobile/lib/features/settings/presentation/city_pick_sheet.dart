import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/settings/presentation/city_search_list.dart';
import 'package:flutter/widgets.dart';

/// The city search as a sheet (A13 D10): resolves to the tapped city, or
/// null when the sheet is dismissed. Writes nothing: setup keeps the pick in
/// its draft until Save. [currentId] is checked in the list.
Future<CatalogCity?> showCityPickSheet(
  BuildContext context, {
  String? currentId,
}) => showFbSheet<CatalogCity>(
  context,
  title: context.l10n.cityPickerTitle,
  builder: (sheet) => Padding(
    // Keeps the search field above the keyboard.
    padding: EdgeInsetsDirectional.only(
      bottom: MediaQuery.viewInsetsOf(sheet).bottom,
    ),
    child: CitySearchList(
      currentId: currentId,
      expand: false,
      onChoose: (city) => Navigator.of(sheet).pop(city),
    ),
  ),
);
