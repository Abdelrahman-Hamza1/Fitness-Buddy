import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-070 UX-040 inline banners golden matrix',
  fileName: 'inline_banners',
  states: {
    'info': (_) => fbGoldenPad(
      const FbInlineBanner(
        kind: FbInlineBannerKind.info,
        message: 'Weights are shown in kilograms.',
      ),
    ),
    'offline': (_) => fbGoldenPad(
      const FbInlineBanner(
        kind: FbInlineBannerKind.offline,
        message: 'You are offline. Buddy needs a connection.',
      ),
    ),
    'pending': (_) => fbGoldenPad(
      const FbInlineBanner(
        kind: FbInlineBannerKind.pending,
        message: 'Waiting to sync.',
      ),
    ),
    'error': (_) => fbGoldenPad(
      const FbInlineBanner(
        kind: FbInlineBannerKind.error,
        message: 'Something went wrong.',
      ),
    ),
    'error action': (_) => fbGoldenPad(
      FbInlineBanner(
        kind: FbInlineBannerKind.error,
        message: 'Could not save this entry, please try again later.',
        actionLabel: 'Retry',
        onAction: () {},
      ),
    ),
  },
);
