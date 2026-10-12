import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _exporter = QrExporter();

Future<ui.Image> _decodePng(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

void main() {
  group('QrExporter.exportPng', () {
    test('produces a PNG at size x pixelRatio', () async {
      final result = await _exporter.exportPng(
        'https://example.com',
        size: 200,
        pixelRatio: 2,
      );
      expect(result.bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      expect(result.width, 400);
      expect(result.height, 400);
      final image = await _decodePng(result.bytes);
      expect(image.width, 400);
      expect(result.validation.status, QrValidationStatus.valid);
      expect(result.validation.decodedText, 'https://example.com');
    });

    test('export matches the on-screen pipeline pixel for pixel', () async {
      const design = QrDesign(
        moduleStyle: QrModuleStyle(
          shape: QrModuleShape.custom,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
        ),
      );
      final exported = await _exporter.exportPng(
        'match',
        design: design,
        size: 240,
      );

      final m = const QrPackageEncoder().encode('match');
      final recorder = ui.PictureRecorder();
      FlexiQrPainter(
        matrix: m,
        design: design,
      ).paint(Canvas(recorder), const Size.square(240));
      final preview = await recorder.endRecording().toImage(240, 240);

      final a = await imageToRgba(await _decodePng(exported.bytes));
      final b = await imageToRgba(preview);
      expect(a, b);
    });

    test('transparent background leaves the quiet zone clear', () async {
      final result = await _exporter.exportPng(
        'clear',
        size: 200,
        transparentBackground: true,
      );
      final px = await imageToRgba(await _decodePng(result.bytes));
      expect(px[3], 0, reason: 'alpha of the top-left pixel');
      expect(result.validation.has(QrIssueCode.transparentBackground), isTrue);
      expect(result.validation.decodedText, 'clear');
    });

    test('strict mode refuses to export an unreadable code', () async {
      await expectLater(
        _exporter.exportPng(
          'hidden',
          design: const QrDesign(
            moduleStyle: QrModuleStyle(color: Color(0xFFFAFAFA)),
          ),
        ),
        throwsA(
          isA<QrValidationException>().having(
            (e) => e.result.status,
            'status',
            QrValidationStatus.invalid,
          ),
        ),
      );
    });

    test('advanced mode exports anyway and reports the risk', () async {
      final result = await _exporter.exportPng(
        'hidden',
        design: const QrDesign(
          moduleStyle: QrModuleStyle(color: Color(0xFFFAFAFA)),
        ),
        validationMode: QrValidationMode.advanced,
      );
      expect(result.bytes, isNotEmpty);
      expect(result.validation.status, QrValidationStatus.invalid);
    });

    test('uses high error correction by default when a logo is set', () async {
      final logo = await _solidImage(const Color(0xFF3F51B5));
      final result = await _exporter.exportPng(
        'https://example.com',
        logoImage: logo,
        design: QrDesign(logo: QrLogo(image: MemoryImage(Uint8List(0)))),
      );
      expect(result.matrix.errorCorrectionLevel, QrErrorCorrectionLevel.high);
      expect(result.validation.decodedText, 'https://example.com');
    });
  });

  group('QrExporter.renderImage', () {
    test('renders a matrix at the requested resolution', () async {
      final m = const QrPackageEncoder().encode('img');
      final image = await _exporter.renderImage(
        matrix: m,
        design: const QrDesign(),
        size: 150,
        pixelRatio: 3,
      );
      expect(image.width, 450);
      expect(image.height, 450);
    });
  });
}

Future<ui.Image> _solidImage(Color color) {
  final recorder = ui.PictureRecorder();
  Canvas(
    recorder,
  ).drawRect(const Rect.fromLTWH(0, 0, 8, 8), Paint()..color = color);
  return recorder.endRecording().toImage(8, 8);
}
