import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

const List<FbOption<String>> _options = [
  FbOption(value: 'a', label: 'Metric', subtitle: 'Grams, millilitres'),
  FbOption(value: 'b', label: 'Imperial', subtitle: 'Ounces, fluid ounces'),
];

Future<void> main() => fbGoldenMatrix(
  'UX-070 UX-040 option sheet golden matrix',
  fileName: 'option_sheet',
  states: {
    'first selected': (_) => FbSheet(
      title: 'Units',
      child: FbOptionList<String>(
        options: _options,
        selected: 'a',
        onSelected: (_) {},
      ),
    ),
    'none selected, no subtitles': (_) => FbSheet(
      title: 'Theme',
      child: FbOptionList<String>(
        options: const [
          FbOption(value: 'a', label: 'Match the phone'),
          FbOption(value: 'b', label: 'Light'),
          FbOption(value: 'c', label: 'Dark'),
        ],
        selected: null,
        onSelected: (_) {},
      ),
    ),
    'long labels': (_) => FbSheet(
      title: 'Week starts on',
      child: FbOptionList<String>(
        options: const [
          FbOption(
            value: 'a',
            label: 'A very long option name that has to wrap on a phone',
            subtitle: 'And a long subtitle that wraps as well, to be sure',
          ),
        ],
        selected: 'a',
        onSelected: (_) {},
      ),
    ),
  },
);
