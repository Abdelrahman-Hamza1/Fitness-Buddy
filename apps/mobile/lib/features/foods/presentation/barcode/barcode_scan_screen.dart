import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/foods/application/barcode_lookup.dart';
import 'package:fb_mobile/features/foods/application/barcode_providers.dart';
import 'package:fb_mobile/features/foods/application/food_search_row.dart';
import 'package:fb_mobile/features/foods/presentation/food_sheet_entry.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// The barcode scanner (FD-030, A28a §1): the camera reads EAN/UPC codes,
/// "Type the code" works without it. A found product opens the food sheet
/// (Add = one tap with the default serving; T17); after a log the scanner
/// closes and the Undo snackbar shows. Not found, incomplete and offline
/// each show a short panel with "Add it yourself". Scans that waited for a
/// connection are listed under the camera (A28a D10).
class BarcodeScanScreen extends ConsumerStatefulWidget {
  /// Creates the scanner for the day [date] and the meal [slotId].
  const new({this.date, this.slotId, super.key});

  /// The diary day to add to; null for today.
  final LocalDate? date;

  /// The meal slot to add to; null to choose by the time of day.
  final String? slotId;

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  MobileScannerController? _camera;
  bool _busy = false;
  BarcodeOutcome? _panel;

  @override
  void initState() {
    super.initState();
    if (ref.read(barcodeCameraEnabledProvider)) {
      _camera = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
        ],
      );
    }
    // Scans that waited for a connection get another try (A28a D10).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        processPendingScans(
          () => ref.read(pendingScansProvider.notifier),
          () => ref.read(barcodeLookupProvider),
        );
      }
    });
  }

  @override
  void dispose() {
    unawaited(_camera?.dispose());
    super.dispose();
  }

  void _pauseCamera() => unawaited(_camera?.stop().catchError((Object _) {}));

  void _resumeCamera() {
    if (!mounted || _panel != null) return;
    unawaited(_camera?.start().catchError((Object _) {}));
  }

  void _onDetect(BarcodeCapture capture) {
    if (_busy || _panel != null) return;
    final barcode = capture.barcodes
        .where((b) => b.rawValue != null)
        .firstOrNull;
    if (barcode == null) return;
    unawaited(HapticFeedback.selectionClick());
    unawaited(
      _lookup(barcode.rawValue!, upcE: barcode.format == BarcodeFormat.upcE),
    );
  }

  Future<void> _lookup(String raw, {bool upcE = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    _pauseCamera();
    final outcome = await ref
        .read(barcodeLookupProvider)
        .lookup(raw, upcE: upcE);
    if (!mounted) return;
    setState(() => _busy = false);
    final pending = ref.read(pendingScansProvider.notifier);
    void processOthers() => processPendingScans(
      () => pending,
      () => ref.read(barcodeLookupProvider),
    );
    // A waiting scan keeps its place until it is logged, saved as your food
    // or dismissed (review fix 3); a later answer only updates it.
    switch (outcome) {
      case BarcodeInvalid():
        showFbSnackBar(context, context.l10n.barcodeInvalid);
        _resumeCamera();
      case BarcodeFound(:final choice, :final product):
        await pending.resolve(
          product.code,
          PendingScanState.ready,
          name: choice.names.en,
          fromOff: product.fromOff,
        );
        if (product.source == ScannedSource.openFoodFacts) processOthers();
        await _openSheet(outcome);
      case BarcodeIncomplete(:final off, :final product):
        await pending.resolve(
          product.code,
          PendingScanState.ready,
          name: off.name,
          fromOff: product.fromOff,
        );
        processOthers();
        setState(() => _panel = outcome);
      case BarcodeNotFound(:final code):
        await pending.resolve(code, PendingScanState.notFound);
        processOthers();
        setState(() => _panel = outcome);
      case BarcodeWaiting(:final code):
        await pending.add(code);
        setState(() => _panel = outcome);
    }
  }

  Future<void> _openSheet(BarcodeFound found) async {
    final choice = found.choice;
    final registry = ref.read(scannedFoodRegistryProvider);
    if (choice.pendingCreate != null) registry.put(choice);
    final logged = await openFoodSheet(
      context,
      FoodPick(
        row: FoodSearchRow(
          choice: choice,
          tier: choice.catalogFood != null
              ? SourceTier.database
              : SourceTier.personal,
        ),
        date: widget.date,
        slotId: widget.slotId,
        scanned: found.product,
      ),
    );
    if (logged) {
      registry.remove(choice.ref.id!);
      await ref.read(pendingScansProvider.notifier).remove(found.product.code);
    } else {
      _resumeCamera();
    }
  }

  void _addYourself(ScanPrefill prefill) {
    // The scan stays pending until the form saves the food (review fix 3).
    ref.read(scanFoodPrefillProvider.notifier).put(prefill);
    setState(() => _panel = null);
    ref
        .read(appNavigatorProvider)
        .push(NewFoodFromScanRoute(date: widget.date, slotId: widget.slotId));
  }

  void _scanAnother() {
    setState(() => _panel = null);
    _resumeCamera();
  }

  Future<void> _typeCode() async {
    final l10n = context.l10n;
    _pauseCamera();
    final code = await showFbSheet<String>(
      context,
      title: l10n.barcodeTypeCodeTitle,
      builder: (_) => const _TypeCodeSheet(),
    );
    if (!mounted) return;
    final digits = code?.replaceAll(RegExp('[^0-9]'), '') ?? '';
    if (digits.isEmpty) {
      _resumeCamera();
      return;
    }
    // Review fix 4: an 8-digit code valid as both EAN-8 and UPC-E is
    // ambiguous; the user says which, the check digit can't.
    final readings = BarcodeLookup.typedReadings(digits);
    if (!mounted) return;
    var reading = readings.length == 1 ? readings.single : null;
    if (readings.length > 1) {
      final l10n = context.l10n;
      reading = await showFbOptionSheet<TypedReading>(
        context,
        title: l10n.barcodeWhichKind,
        options: [
          FbOption(value: TypedReading.gtin, label: l10n.barcodeKindEan8),
          FbOption(value: TypedReading.upcE, label: l10n.barcodeKindUpcE),
        ],
        selected: null,
      );
      if (!mounted) return;
      if (reading == null) {
        _resumeCamera();
        return;
      }
    }
    setState(() => _panel = null);
    await _lookup(digits, upcE: reading == TypedReading.upcE);
  }

  Future<void> _openPending(PendingScan scan) async {
    switch (scan.state) {
      case PendingScanState.notFound:
        _addYourself(ScanPrefill(code: scan.code));
      case PendingScanState.waiting || PendingScanState.ready:
        setState(() => _panel = null);
        await _lookup(scan.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pending = ref.watch(pendingScansProvider).value ?? const [];
    final camera = _camera;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.barcodeScanTitle),
        actions: [
          FbButton.text(
            key: const ValueKey('barcode-type-code'),
            label: l10n.barcodeTypeCode,
            onPressed: _busy ? null : () => unawaited(_typeCode()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: FbSpace.s6),
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (camera != null)
                  MobileScanner(
                    controller: camera,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) => _CameraProblem(
                      denied:
                          error.errorCode ==
                          MobileScannerErrorCode.permissionDenied,
                    ),
                  )
                else
                  const _CameraProblem(denied: false),
                if (_busy)
                  ColoredBox(
                    color: Theme.of(context).colorScheme.scrim
                        .withValues(alpha: 0.4),
                    child: Center(
                      child: Semantics(
                        liveRegion: true,
                        label: l10n.barcodeLookingUp,
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(FbSpace.s4),
            child: switch (_panel) {
              BarcodeNotFound(:final code) => _Panel(
                title: l10n.barcodeNotFoundTitle,
                body: l10n.barcodeNotFoundBody,
                action: l10n.barcodeAddYourself,
                onAction: () => _addYourself(ScanPrefill(code: code)),
                onAnother: _scanAnother,
              ),
              BarcodeWaiting(:final code) => _Panel(
                title: l10n.barcodeWaitingTitle,
                body: l10n.barcodeWaitingBody,
                action: l10n.barcodeAddYourself,
                onAction: () => _addYourself(ScanPrefill(code: code)),
                onAnother: _scanAnother,
              ),
              BarcodeIncomplete(:final off, :final prefill, :final product) =>
                _Panel(
                  title: l10n.barcodeIncompleteTitle,
                  body: off.name == null
                      ? l10n.barcodeIncompleteBodyNoName
                      : l10n.barcodeIncompleteBody(off.name!),
                  action: l10n.barcodeAddMissing,
                  onAction: () => _addYourself(prefill),
                  onAnother: _scanAnother,
                  attribution: product.fromOff,
                ),
              _ => Text(
                l10n.barcodeScanHint,
                style: FbType.body.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            },
          ),
          if (pending.isNotEmpty) ...[
            FbSectionHeader(title: l10n.barcodePendingTitle),
            for (final scan in pending)
              FbListRow(
                key: ValueKey('pending-${scan.code}'),
                title: scan.name ?? l10n.barcodeProductCode(scan.code),
                subtitle: switch (scan.state) {
                  PendingScanState.waiting => l10n.barcodePendingWaiting,
                  PendingScanState.ready when scan.fromOff =>
                    l10n.barcodePendingReadyOff,
                  PendingScanState.ready => l10n.barcodePendingReady,
                  PendingScanState.notFound => l10n.barcodePendingNotFound,
                },
                trailing: FbIconButton(
                  icon: FbIcons.close,
                  tooltip: l10n.barcodePendingRemove,
                  onPressed: () => unawaited(
                    ref.read(pendingScansProvider.notifier).remove(scan.code),
                  ),
                ),
                onTap: _busy ? null : () => unawaited(_openPending(scan)),
              ),
          ],
        ],
      ),
    );
  }
}

/// The "Type the code" sheet; it owns its text field's controller, so the
/// controller outlives the sheet's closing animation.
class _TypeCodeSheet extends StatefulWidget {
  const new();

  @override
  State<_TypeCodeSheet> createState() => _TypeCodeSheetState();
}

class _TypeCodeSheetState extends State<_TypeCodeSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        FbTextField(
          controller: _controller,
          label: l10n.barcodeTypeCodeLabel,
          hint: l10n.barcodeTypeCodeHint,
          keyboardType: TextInputType.number,
          maxLength: 14,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (text) => Navigator.of(context).pop(text),
        ),
        FbButton.primary(
          label: l10n.barcodeLookUp,
          expand: true,
          onPressed: () => Navigator.of(context).pop(_controller.text),
        ),
      ],
    );
  }
}

/// The camera can't run: permission off, or no camera. Typing the code
/// still works.
class _CameraProblem extends StatelessWidget {
  const new({required this.denied});

  final bool denied;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(FbSpace.s4),
          child: Text(
            denied ? l10n.barcodeCameraDenied : l10n.barcodeCameraUnavailable,
            textAlign: TextAlign.center,
            style: FbType.body.copyWith(color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// A result that needs a choice: add the product yourself or scan another.
class _Panel extends StatelessWidget {
  const new({
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
    required this.onAnother,
    this.attribution = false,
  });

  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;
  final VoidCallback onAnother;
  final bool attribution;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s2,
        children: [
          Text(title, style: FbType.title.copyWith(color: scheme.onSurface)),
          Text(body, style: FbType.body.copyWith(color: scheme.onSurface)),
          if (attribution)
            Text(
              l10n.offAttribution,
              style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
            ),
          FbButton.primary(label: action, onPressed: onAction, expand: true),
          FbButton.text(label: l10n.barcodeScanAnother, onPressed: onAnother),
        ],
      ),
    );
  }
}
