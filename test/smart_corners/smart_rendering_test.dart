import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);

// 21 modules + no quiet zone at 210 px -> 10 px per module, cell (r, c)
// starts at (10c, 10r).
const _px = 10;

QrMatrix _matrix(List<(int, int)> dark) {
  final rows = List.generate(21, (_) => List.filled(21, false));
  for (final (r, c) in dark) {
    rows[r][c] = true;
  }
  return QrMatrix.fromModules(rows);
}

class _Raster {
  _Raster(this.bytes);
  final ByteData bytes;

  Color at(int x, int y) {
    final i = (y * 210 + x) * 4;
    return Color.fromARGB(
      bytes.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
  }

  /// Pixel just inside the given corner of cell (row, col).
  Color corner(int row, int col, QrCorner corner) {
    final x = col * _px, y = row * _px;
    return switch (corner) {
      QrCorner.topLeft => at(x, y),
      QrCorner.topRight => at(x + _px - 1, y),
      QrCorner.bottomRight => at(x + _px - 1, y + _px - 1),
      QrCorner.bottomLeft => at(x, y + _px - 1),
    };
  }

  Color center(int row, int col) => at(col * _px + 5, row * _px + 5);
}

Future<_Raster> _render(QrMatrix m, QrDesign design) async {
  final recorder = ui.PictureRecorder();
  QrRenderPipeline(
    matrix: m,
    design: design.copyWith(quietZone: 0),
  ).paint(Canvas(recorder), const Size.square(210));
  final image = await recorder.endRecording().toImage(210, 210);
  final bytes = await image.toByteData();
  image.dispose();
  return _Raster(bytes!);
}

QrDesign _shape(QrModuleShape shape) =>
    QrDesign(moduleStyle: QrModuleStyle(shape: shape));

void main() {
  group('connected shape', () {
    // A horizontal pair: (10,10)(10,11).
    final pair = _matrix([(10, 10), (10, 11)]);

    test('rounds outer corners and keeps the joint sharp', () async {
      final r = await _render(pair, _shape(QrModuleShape.connected));
      expect(r.corner(10, 10, QrCorner.topLeft), _white);
      expect(r.corner(10, 10, QrCorner.bottomLeft), _white);
      expect(r.corner(10, 11, QrCorner.topRight), _white);
      expect(r.corner(10, 11, QrCorner.bottomRight), _white);
      // Corners on the shared edge stay sharp: no gap between modules.
      expect(r.corner(10, 10, QrCorner.topRight), _black);
      expect(r.corner(10, 11, QrCorner.topLeft), _black);
      expect(r.corner(10, 10, QrCorner.bottomRight), _black);
      expect(r.corner(10, 11, QrCorner.bottomLeft), _black);
    });

    test('an isolated module becomes a circle', () async {
      final r = await _render(
        _matrix([(5, 15)]),
        _shape(QrModuleShape.connected),
      );
      expect(r.center(5, 15), _black);
      for (final c in QrCorner.values) {
        expect(r.corner(5, 15, c), _white, reason: '$c');
      }
    });

    test('does not fill concave corners', () async {
      // L shape: (10,10) (10,11) (11,10); (11,11) is the light inner corner.
      final r = await _render(
        _matrix([(10, 10), (10, 11), (11, 10)]),
        _shape(QrModuleShape.connected),
      );
      expect(r.corner(11, 11, QrCorner.topLeft), _white);
    });
  });

  group('smooth shape', () {
    test('fills the concave corner of an L junction', () async {
      final r = await _render(
        _matrix([(10, 10), (10, 11), (11, 10)]),
        _shape(QrModuleShape.smooth),
      );
      expect(r.corner(11, 11, QrCorner.topLeft), _black);
      expect(r.center(11, 11), _white, reason: 'fillet stays in the corner');
      expect(r.corner(10, 10, QrCorner.topLeft), _white, reason: 'outer');
    });

    test('does not bridge modules touching only diagonally', () async {
      final r = await _render(
        _matrix([(10, 10), (11, 11)]),
        _shape(QrModuleShape.smooth),
      );
      expect(r.corner(10, 11, QrCorner.bottomLeft), _white);
      expect(r.corner(11, 10, QrCorner.topRight), _white);
      expect(r.corner(10, 10, QrCorner.bottomRight), _white);
    });

    test('skips fillets when modules do not fill their cells', () async {
      final r = await _render(
        _matrix([(10, 10), (10, 11), (11, 10)]),
        const QrDesign(
          moduleStyle: QrModuleStyle(shape: QrModuleShape.smooth, scale: 0.8),
        ),
      );
      expect(r.corner(11, 11, QrCorner.topLeft), _white);
    });
  });

  group('smart corner mode on rounded/custom shapes', () {
    final pair = _matrix([(10, 10), (10, 11)]);
    const radius = BorderRadius.all(Radius.circular(5));

    test('manual mode rounds every corner, even at joints', () async {
      final r = await _render(
        pair,
        const QrDesign(
          moduleStyle: QrModuleStyle(
            shape: QrModuleShape.custom,
            borderRadius: radius,
          ),
        ),
      );
      expect(r.corner(10, 10, QrCorner.topRight), _white);
    });

    test('smart mode sharpens the joint', () async {
      final r = await _render(
        pair,
        const QrDesign(
          moduleStyle: QrModuleStyle(
            shape: QrModuleShape.custom,
            borderRadius: radius,
            cornerMode: QrCornerMode.smart,
          ),
        ),
      );
      expect(r.corner(10, 10, QrCorner.topLeft), _white);
      expect(r.corner(10, 10, QrCorner.topRight), _black);
    });

    test('smart mode keeps per-corner base radii', () async {
      // Only topLeft is rounded in the base; an isolated module keeps the
      // other three corners sharp.
      final r = await _render(
        _matrix([(5, 5)]),
        const QrDesign(
          moduleStyle: QrModuleStyle(
            shape: QrModuleShape.custom,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(5)),
            cornerMode: QrCornerMode.smart,
          ),
        ),
      );
      expect(r.corner(5, 5, QrCorner.topLeft), _white);
      expect(r.corner(5, 5, QrCorner.topRight), _black);
      expect(r.corner(5, 5, QrCorner.bottomRight), _black);
      expect(r.corner(5, 5, QrCorner.bottomLeft), _black);
    });

    test('moduleBuilder can override smart decisions per module', () async {
      final r = await _render(
        pair,
        QrDesign(
          moduleStyle: const QrModuleStyle(shape: QrModuleShape.connected),
          moduleBuilder: (m) => m.col == 10
              ? const QrModuleStyle(
                  shape: QrModuleShape.custom,
                  borderRadius: radius,
                )
              : null,
        ),
      );
      expect(r.corner(10, 10, QrCorner.topRight), _white, reason: 'manual');
      expect(r.corner(10, 11, QrCorner.topLeft), _black, reason: 'smart');
    });

    test('a custom engine replaces the default rules', () async {
      final r = await _render(
        pair,
        _shape(
          QrModuleShape.connected,
        ).copyWith(smartCornerEngine: const _NeverRoundEngine()),
      );
      for (final c in QrCorner.values) {
        expect(r.corner(10, 10, c), _black, reason: '$c');
      }
    });
  });

  group('geometry exposes resolved radii to renderers', () {
    test('custom renderers receive smart-resolved corners', () {
      final spy = _SpyRenderer();
      const ctx = QrModuleContext(
        row: 0,
        col: 0,
        isDark: true,
        type: QrModuleType.data,
        neighbors: QrNeighbors(right: true),
      );
      buildModulePath(
        const Rect.fromLTWH(0, 0, 20, 20),
        ctx,
        QrModuleStyle(
          renderer: spy,
          borderRadius: BorderRadius.circular(4),
          cornerMode: QrCornerMode.smart,
        ),
      );
      expect(
        spy.received!.borderRadius,
        const BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
      );
    });
  });
}

class _NeverRoundEngine extends QrSmartCornerEngine {
  const _NeverRoundEngine();

  @override
  Set<QrCorner> exposedCorners(QrNeighbors neighbors) => const {};
}

class _SpyRenderer extends QrModuleRenderer {
  QrModuleGeometry? received;

  @override
  Path buildPath(QrModuleGeometry geometry) {
    received = geometry;
    return Path()..addRect(geometry.rect);
  }
}
