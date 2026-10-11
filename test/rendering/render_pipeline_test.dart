import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _encoder = QrPackageEncoder();

/// Rasterized RGBA output of the pipeline.
class _Raster {
  _Raster(this.bytes, this.width);
  final ByteData bytes;
  final int width;

  Color at(int x, int y) {
    final i = (y * width + x) * 4;
    return Color.fromARGB(
      bytes.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
  }
}

Future<_Raster> _render(QrMatrix m, QrDesign d, int size) async {
  final recorder = ui.PictureRecorder();
  QrRenderPipeline(
    matrix: m,
    design: d,
  ).paint(Canvas(recorder), Size.square(size.toDouble()));
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData();
  image.dispose();
  return _Raster(bytes!, size);
}

const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);

void main() {
  // Version 1 + default quiet zone = 29 modules -> 10 px per module at 290.
  final m = _encoder.encode('flexi');
  const px = 10;
  const qz = 4;
  int x(int col) => (qz + col) * px;

  group('QrRenderLayout', () {
    test('fits the symbol and quiet zone into the shortest side', () {
      final l = QrRenderLayout.compute(const Size(400, 290), 21, 4);
      expect(l.moduleExtent, 10);
      expect(l.bounds, const Rect.fromLTWH(55, 0, 290, 290));
      expect(l.cellRect(0, 0), const Rect.fromLTWH(95, 40, 10, 10));
      expect(l.matrixRect, const Rect.fromLTWH(95, 40, 210, 210));
    });

    test('supports a zero quiet zone', () {
      final l = QrRenderLayout.compute(const Size.square(210), 21, 0);
      expect(l.cellRect(20, 20), const Rect.fromLTWH(200, 200, 10, 10));
    });
  });

  group('QrRenderPipeline', () {
    test('every module center matches the matrix', () async {
      final r = await _render(m, const QrDesign(), 290);
      for (var row = 0; row < m.size; row++) {
        for (var col = 0; col < m.size; col++) {
          expect(
            r.at(x(col) + 5, x(row) + 5),
            m.isDark(row, col) ? _black : _white,
            reason: '($row, $col)',
          );
        }
      }
    });

    test('quiet zone is background', () async {
      final r = await _render(m, const QrDesign(), 290);
      expect(r.at(1, 1), _white);
      expect(r.at(39, 150), _white);
      expect(r.at(288, 288), _white);
    });

    test('transparent background leaves pixels clear', () async {
      final r = await _render(
        m,
        const QrDesign(backgroundColor: Color(0x00000000)),
        290,
      );
      expect(r.at(1, 1).a, 0);
      expect(r.at(x(0) + 5, x(0) + 5), _black);
    });

    test('mixed corners render: three rounded, bottom-left sharp', () async {
      const design = QrDesign(
        moduleStyle: QrModuleStyle(
          shape: QrModuleShape.custom,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(5),
            topRight: Radius.circular(5),
            bottomRight: Radius.circular(5),
          ),
        ),
      );
      final r = await _render(m, design, 290);
      // Module (0,0) is the dark top-left finder corner.
      final left = x(0), top = x(0);
      expect(r.at(left, top), _white, reason: 'topLeft rounded');
      expect(r.at(left + 9, top), _white, reason: 'topRight rounded');
      expect(r.at(left + 9, top + 9), _white, reason: 'bottomRight rounded');
      expect(r.at(left, top + 9), _black, reason: 'bottomLeft sharp');
      expect(r.at(left + 5, top + 5), _black);
    });

    test('opacity blends module color with the background', () async {
      final r = await _render(
        m,
        const QrDesign(moduleStyle: QrModuleStyle(opacity: 0.5)),
        290,
      );
      final c = r.at(x(0) + 5, x(0) + 5);
      expect((c.r * 255).round(), closeTo(127, 2));
    });

    test('gradient spans the symbol', () async {
      const design = QrDesign(
        moduleStyle: QrModuleStyle(
          gradient: LinearGradient(
            colors: [Color(0xFFFF0000), Color(0xFF0000FF)],
          ),
        ),
      );
      final r = await _render(m, design, 290);
      final left = r.at(x(0) + 5, x(0) + 5);
      final right = r.at(x(20) + 5, x(0) + 5);
      expect(left.r, greaterThan(left.b));
      expect(right.b, greaterThan(right.r));
    });

    test('moduleBuilder styles individual modules', () async {
      final design = QrDesign(
        moduleBuilder: (module) => module.type == QrModuleType.data
            ? const QrModuleStyle(color: Color(0xFFFF0000))
            : null,
      );
      final r = await _render(m, design, 290);
      expect(r.at(x(0) + 5, x(0) + 5), _black, reason: 'finder untouched');
      for (final ctx in m.modules) {
        if (ctx.isDark && ctx.type == QrModuleType.data) {
          expect(r.at(x(ctx.col) + 5, x(ctx.row) + 5), const Color(0xFFFF0000));
          break;
        }
      }
    });

    test('moduleBuilder is only called for dark modules', () {
      final seen = <QrModuleContext>[];
      final design = QrDesign(
        moduleBuilder: (module) {
          seen.add(module);
          return null;
        },
      );
      QrRenderPipeline(
        matrix: m,
        design: design,
      ).paint(Canvas(ui.PictureRecorder()), const Size.square(290));
      final darkCount = m.modules.where((c) => c.isDark).length;
      expect(seen.length, darkCount);
      expect(seen.every((c) => c.isDark), isTrue);
    });
  });
}
