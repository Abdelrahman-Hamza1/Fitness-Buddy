import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/foods/application/barcode_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Today's hint that scans which waited for a connection were looked up
/// (A28a D10, #229): "2 scanned products are ready", with Show (the
/// scanner, which lists them). Nothing otherwise.
///
/// It starts watching only after the frame it first appears in, so its
/// preference read never runs before (or during) the first frame (UX-001).
class ReadyScansTodayHint extends ConsumerStatefulWidget {
  /// Creates the hint.
  const new({super.key});

  @override
  ConsumerState<ReadyScansTodayHint> createState() =>
      _ReadyScansTodayHintState();
}

class _ReadyScansTodayHintState extends ConsumerState<ReadyScansTodayHint> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final scans = ref.watch(pendingScansProvider).value ?? const [];
    final count = scans.where((s) => s.state == PendingScanState.ready).length;
    if (count == 0) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: FbSpace.s3),
      child: FbInlineBanner(
        key: const ValueKey('today-ready-scans'),
        kind: FbInlineBannerKind.info,
        message: l10n.barcodeReadyHint(count),
        actionLabel: l10n.barcodeReadyShow,
        onAction: () =>
            ref.read(appNavigatorProvider).push(const BarcodeScanRoute()),
      ),
    );
  }
}
