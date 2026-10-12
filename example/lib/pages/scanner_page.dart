import 'package:flexi_qr_kit/scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Overlay looks offered by the scanner page.
enum OverlayPreset {
  brackets('Brackets', QrScannerOverlayStyle()),
  asymmetric(
    'Asymmetric',
    QrScannerOverlayStyle(
      frame: QrScannerFrameStyle(
        color: Color(0xFF69F0AE),
        strokeWidth: 6,
        cornerLength: 48,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
    ),
  ),
  twoCorners(
    'Two corners',
    QrScannerOverlayStyle(
      frame: QrScannerFrameStyle(
        corners: {QrCorner.topLeft, QrCorner.bottomRight},
        borderRadius: BorderRadius.zero,
        strokeCap: StrokeCap.square,
        cornerLength: 56,
      ),
    ),
  ),
  fullBorder(
    'Full border',
    QrScannerOverlayStyle(
      windowSize: Size(280, 200),
      overlayColor: Color(0xCC000000),
      frame: QrScannerFrameStyle(
        fullBorder: true,
        color: Color(0xFFFFC107),
        strokeWidth: 3,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
  ),
  none('No overlay', null);

  const OverlayPreset(this.label, this.style);

  final String label;
  final QrScannerOverlayStyle? style;
}

/// Live camera scanner with overlay presets, torch and camera switching.
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, this.controller});

  /// Camera controller; created by the page when null.
  final MobileScannerController? controller;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late final MobileScannerController _controller =
      widget.controller ??
      MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  OverlayPreset _preset = OverlayPreset.brackets;
  bool _restrict = true;
  final _results = <QrScanResult>[];

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onDetect(QrScanResult result) {
    setState(() => _results.insert(0, result));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              FlexiQrScanner(
                controller: _controller,
                onDetect: _onDetect,
                overlayStyle: _preset.style,
                restrictToScanWindow: _restrict,
                errorBuilder: (context, error) => _CameraError(error: error),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      key: const Key('torch'),
                      tooltip: 'Torch',
                      onPressed: _controller.toggleTorch,
                      icon: ValueListenableBuilder(
                        valueListenable: _controller,
                        builder: (context, state, _) => Icon(
                          state.torchState == TorchState.on
                              ? Icons.flash_on
                              : Icons.flash_off,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      key: const Key('switch-camera'),
                      tooltip: 'Switch camera',
                      onPressed: _controller.switchCamera,
                      icon: const Icon(Icons.cameraswitch),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final preset in OverlayPreset.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: Key('overlay-${preset.name}'),
                    label: Text(preset.label),
                    selected: _preset == preset,
                    onSelected: (_) => setState(() => _preset = preset),
                  ),
                ),
            ],
          ),
        ),
        SwitchListTile(
          key: const Key('restrict'),
          dense: true,
          title: const Text('Only scan inside the window'),
          value: _restrict,
          onChanged: (v) => setState(() => _restrict = v),
        ),
        SizedBox(
          height: 140,
          child: _results.isEmpty
              ? const Center(child: Text('Point the camera at a QR code'))
              : ListView.builder(
                  key: const Key('results'),
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final result = _results[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.qr_code_2),
                      title: Text(
                        result.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: 'Copy',
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () => Clipboard.setData(
                          ClipboardData(text: result.value),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final message = error.errorCode == MobileScannerErrorCode.permissionDenied
        ? 'Camera permission denied. Allow it in the system settings.'
        : 'Camera unavailable: ${error.errorDetails?.message ?? error.errorCode.name}';
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
