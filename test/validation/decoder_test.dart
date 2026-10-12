import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _encoder = QrPackageEncoder();
const _decoder = ZxingQrDecoder();

Future<String?> _roundTrip(
  String data, {
  QrDesign design = const QrDesign(),
  QrErrorCorrectionLevel level = QrErrorCorrectionLevel.medium,
  double size = 400,
  ui.Image? logoImage,
}) async {
  final m = _encoder.encode(data, errorCorrectionLevel: level);
  final image = await renderQrImage(
    matrix: m,
    design: design,
    size: size,
    logoImage: logoImage,
  );
  final rgba = await imageToRgba(image);
  final text = _decoder.decode(rgba, image.width, image.height);
  image.dispose();
  return text;
}

Future<ui.Image> _solid(Color color, int size) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = color,
  );
  return recorder.endRecording().toImage(size, size);
}

void main() {
  group('ZxingQrDecoder', () {
    test('decodes a plain code', () async {
      expect(await _roundTrip('https://example.com'), 'https://example.com');
    });

    test('decodes Unicode, Arabic and emoji payloads', () async {
      for (final text in ['مرحبا بالعالم', 'héllo 世界 🚀', 'Ünïcödé']) {
        expect(await _roundTrip(text), text);
      }
    });

    test('returns null for an image without a code', () {
      final blank = Uint8List(100 * 100 * 4)..fillRange(0, 100 * 100 * 4, 255);
      expect(_decoder.decode(blank, 100, 100), isNull);
    });

    test('composites transparent pixels over white', () async {
      final text = await _roundTrip(
        'transparent',
        design: const QrDesign(backgroundColor: Color(0x00000000)),
      );
      expect(text, 'transparent');
    });
  });

  // An independent decoder reads every built-in style. This is the main
  // guard that styling never breaks the encoded data.
  group('built-in styles stay readable', () {
    const data = 'https://example.com/flexi_qr_kit?ref=readability';
    for (final shape in QrModuleShape.values) {
      test('module shape ${shape.name}', () async {
        expect(
          await _roundTrip(
            data,
            design: QrDesign(moduleStyle: QrModuleStyle(shape: shape)),
          ),
          data,
        );
      });
    }

    test('mixed corners: bottomLeft sharp, others rounded', () async {
      const design = QrDesign(
        moduleStyle: QrModuleStyle(
          shape: QrModuleShape.custom,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
      );
      expect(await _roundTrip(data, design: design), data);
    });

    for (final (name, style) in [
      ('square', QrFinderStyle.square()),
      ('rounded', QrFinderStyle.rounded()),
      ('circle', QrFinderStyle.circle()),
      ('thick', const QrFinderStyle(outerThickness: 1.2)),
    ]) {
      test('finder preset $name', () async {
        expect(
          await _roundTrip(
            data,
            design: QrDesign(
              moduleStyle: const QrModuleStyle(shape: QrModuleShape.dots),
              finderStyle: style,
            ),
          ),
          data,
        );
      });
    }

    test('centered logo with high error correction', () async {
      final logo = await _solid(const Color(0xFF3F51B5), 16);
      final text = await _roundTrip(
        data,
        level: QrErrorCorrectionLevel.high,
        logoImage: logo,
        design: QrDesign(
          moduleStyle: const QrModuleStyle(shape: QrModuleShape.dots),
          finderStyle: QrFinderStyle.rounded(),
          logo: QrLogo(
            image: MemoryImage(Uint8List(0)),
            sizeFactor: 0.25,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
      expect(text, data);
    });
  });
}
