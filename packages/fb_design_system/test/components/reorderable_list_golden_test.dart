import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

Widget _list({List<String> items = const ['Breakfast', 'Lunch', 'Snacks']}) =>
    SizedBox(
      height: 360,
      child: FbReorderableList<String>(
        items: items,
        idOf: (meal) => meal,
        itemBuilder: (context, meal, handle) => FbListRow(
          title: meal,
          subtitle: '4:00 AM – 11:00 AM',
          trailing: handle,
        ),
        onReorder: (_, _) {},
      ),
    );

Future<void> main() => fbGoldenMatrix(
  'DY-010 UX-070 reorderable list golden matrix',
  fileName: 'reorderable_list',
  states: {
    'rows': (_) => _list(),
    'disabled': (_) => SizedBox(
      height: 360,
      child: FbReorderableList<String>(
        items: const ['Breakfast', 'Lunch'],
        idOf: (meal) => meal,
        enabled: false,
        itemBuilder: (context, meal, handle) =>
            FbListRow(title: meal, trailing: handle),
        onReorder: (_, _) {},
      ),
    ),
    'long name': (_) =>
        _list(items: const ['A meal with a rather long name that wraps']),
  },
);
