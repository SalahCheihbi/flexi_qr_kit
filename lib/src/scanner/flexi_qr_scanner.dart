import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'qr_scan_result.dart';
import 'qr_scanner_overlay.dart';
import 'qr_scanner_overlay_style.dart';

/// Builds a widget shown in place of the preview when the camera fails.
typedef QrScannerErrorBuilder =
    Widget Function(BuildContext context, MobileScannerException error);

/// Camera preview that reads QR codes, with a customizable overlay.
///
/// ```dart
/// FlexiQrScanner(
///   onDetect: (result) => print(result.value),
///   overlayStyle: QrScannerOverlayStyle(
///     frame: QrScannerFrameStyle(
///       borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
///     ),
///   ),
/// )
/// ```
///
/// Built on `mobile_scanner`: add the camera permission to your app as its
/// documentation describes.
class FlexiQrScanner extends StatefulWidget {
  /// Creates a QR scanner.
  const FlexiQrScanner({
    super.key,
    required this.onDetect,
    this.controller,
    this.overlayStyle = const QrScannerOverlayStyle(),
    this.restrictToScanWindow = true,
    this.duplicateCooldown = const Duration(seconds: 2),
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.placeholderBuilder,
  });

  /// Called once per new code. Repeated sightings of the same value are
  /// dropped until it has been out of view for [duplicateCooldown].
  final ValueChanged<QrScanResult> onDetect;

  /// Camera controller, for torch, camera switching or pausing. When null,
  /// the scanner creates one limited to QR codes and disposes it.
  final MobileScannerController? controller;

  /// Overlay drawn over the preview, or null for none.
  final QrScannerOverlayStyle? overlayStyle;

  /// Only read codes inside the overlay's scan window. Has no effect
  /// without an [overlayStyle], nor on the web.
  final bool restrictToScanWindow;

  /// How long a value must go unseen before it is reported again. Zero
  /// reports every sighting.
  final Duration duplicateCooldown;

  /// How the preview fills the available space.
  final BoxFit fit;

  /// Shown when the camera cannot start, for example without permission.
  final QrScannerErrorBuilder? errorBuilder;

  /// Shown while the camera starts.
  final WidgetBuilder? placeholderBuilder;

  @override
  State<FlexiQrScanner> createState() => _FlexiQrScannerState();
}

class _FlexiQrScannerState extends State<FlexiQrScanner> {
  MobileScannerController? _ownedController;
  late QrScanDeduplicator _deduplicator = QrScanDeduplicator(
    cooldown: widget.duplicateCooldown,
  );

  MobileScannerController get _controller =>
      widget.controller ??
      (_ownedController ??= MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
      ));

  @override
  void didUpdateWidget(FlexiQrScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duplicateCooldown != oldWidget.duplicateCooldown) {
      _deduplicator = QrScanDeduplicator(cooldown: widget.duplicateCooldown);
    }
    if (widget.controller != null && _ownedController != null) {
      _ownedController!.dispose();
      _ownedController = null;
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  void _handleCapture(BarcodeCapture capture) {
    final now = DateTime.now();
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (barcode.format != BarcodeFormat.qrCode || value == null) continue;
      if (_deduplicator.accept(value, now)) {
        widget.onDetect(QrScanResult.fromBarcode(barcode));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlayStyle = widget.overlayStyle;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scanWindow = overlayStyle != null && widget.restrictToScanWindow
            ? overlayStyle.scanWindowFor(constraints.biggest)
            : null;
        return Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _handleCapture,
              fit: widget.fit,
              scanWindow: scanWindow,
              errorBuilder: widget.errorBuilder,
              placeholderBuilder: widget.placeholderBuilder,
            ),
            if (overlayStyle != null) QrScannerOverlay(style: overlayStyle),
          ],
        );
      },
    );
  }
}
