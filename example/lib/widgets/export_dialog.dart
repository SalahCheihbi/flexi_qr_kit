import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/material.dart';

/// Exports the code as a validated PNG and shows the result.
Future<void> showExportDialog(
  BuildContext context, {
  required String data,
  required QrDesign design,
  QrErrorCorrectionLevel? errorCorrectionLevel,
  QrExporter exporter = const QrExporter(),
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _ExportDialog(
      export: exporter.exportPng(
        data,
        design: design,
        errorCorrectionLevel: errorCorrectionLevel,
        size: 300,
        pixelRatio: 4,
        // Show the issues instead of throwing, so invalid codes can be
        // inspected too.
        validationMode: QrValidationMode.advanced,
      ),
    ),
  );
}

class _ExportDialog extends StatelessWidget {
  const _ExportDialog({required this.export});

  final Future<QrExportResult> export;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PNG export'),
      content: FutureBuilder<QrExportResult>(
        future: export,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Export failed: ${snapshot.error}');
          }
          final result = snapshot.data;
          if (result == null) {
            return const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final kb = (result.bytes.length / 1024).toStringAsFixed(1);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 220,
                child: Image.memory(result.bytes, key: const Key('export')),
              ),
              const SizedBox(height: 12),
              Text('${result.width} × ${result.height} px · $kb KB'),
              Text('Validation: ${result.validation.status.name}'),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
