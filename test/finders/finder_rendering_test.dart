import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);
const _red = Color(0xFFFF0000);
const _blue = Color(0xFF0000FF);
const _green = Color(0xFF00FF00);
const _yellow = Color(0xFFFFFF00);

// Version 1 (21x21) at 210 px without quiet zone -> 10 px per module, cell
// (r, c) starts at (10c, 10r).
const _side = 210;
final _matrix = const QrPackageEncoder().encode(
  'flexi',
  errorCorrectionLevel: QrErrorCorrectionLevel.low,
  version: 1,
);

class _Raster {
  _Raster(this.bytes, this.side);
  final ByteData bytes;
  final int side;

  Color at(int x, int y) {
    final i = (y * side + x) * 4;
    return Color.fromARGB(
      bytes.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
  }

  Color center(int row, int col, {int offset = 0}) =>
      at(offset + col * 10 + 5, offset + row * 10 + 5);
}

Future<_Raster> _render(QrDesign design, {int quietZone = 0}) async {
  final side = _side + 2 * quietZone * 10;
  final recorder = ui.PictureRecorder();
  QrRenderPipeline(
    matrix: _matrix,
    design: design.copyWith(quietZone: quietZone),
  ).paint(Canvas(recorder), Size.square(side.toDouble()));
  final image = await recorder.endRecording().toImage(side, side);
  final bytes = await image.toByteData();
  image.dispose();
  return _Raster(bytes!, side);
}

class _DiamondEyeRenderer extends DefaultQrFinderRenderer {
  const _DiamondEyeRenderer();

  @override
  Path buildInner(QrFinderGeometry geometry) {
    final r = geometry.innerRect;
    return Path()
      ..moveTo(r.center.dx, r.top)
      ..lineTo(r.right, r.center.dy)
      ..lineTo(r.center.dx, r.bottom)
      ..lineTo(r.left, r.center.dy)
      ..close();
  }
}

void main() {
  group('finder styles', () {
    test('without finder styles, finders render as plain modules', () async {
      final r = await _render(const QrDesign());
      for (final (row, col) in [(0, 0), (0, 14), (14, 0), (3, 3), (3, 17)]) {
        expect(r.center(row, col), _black, reason: '($row, $col)');
      }
      expect(r.center(1, 1), _white);
    });

    test('outer, inner and gap are colored independently', () async {
      final r = await _render(
        const QrDesign(
          finderStyle: QrFinderStyle(
            outer: QrFinderPartStyle(color: _red),
            inner: QrFinderPartStyle(color: _blue),
          ),
        ),
      );
      for (final pos in QrFinderPosition.values) {
        final (r0, c0) = pos.origin(21);
        expect(r.center(r0, c0), _red, reason: '$pos outer');
        expect(r.center(r0 + 6, c0 + 3), _red, reason: '$pos outer');
        expect(r.center(r0 + 1, c0 + 1), _white, reason: '$pos gap');
        expect(r.center(r0 + 3, c0 + 3), _blue, reason: '$pos inner');
      }
    });

    test('each finder position can be styled on its own', () async {
      final r = await _render(
        const QrDesign(
          finderStyle: QrFinderStyle(outer: QrFinderPartStyle(color: _green)),
          topLeftFinderStyle: QrFinderStyle(
            outer: QrFinderPartStyle(color: _red),
          ),
          bottomLeftFinderStyle: QrFinderStyle(
            inner: QrFinderPartStyle(color: _blue),
          ),
        ),
      );
      expect(r.center(0, 0), _red);
      expect(r.center(0, 14), _green);
      expect(r.center(14, 0), _black);
      expect(r.center(17, 3), _blue);
      expect(r.center(3, 17), _black);
    });

    test('a single override leaves the other finders as modules', () async {
      final r = await _render(
        const QrDesign(
          moduleStyle: QrModuleStyle(color: _green),
          topRightFinderStyle: QrFinderStyle(
            outer: QrFinderPartStyle(color: _red),
          ),
        ),
      );
      expect(r.center(0, 14), _red);
      expect(r.center(0, 0), _green);
      expect(r.center(14, 0), _green);
    });

    test('styled finders replace their modules entirely', () async {
      final r = await _render(
        const QrDesign(
          moduleStyle: QrModuleStyle(color: _green),
          finderStyle: QrFinderStyle(
            outer: QrFinderPartStyle(
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ),
        ),
      );
      // The rounded corner leaves the background visible: no square module
      // is drawn underneath.
      expect(r.at(0, 0), _white);
      expect(r.at(209, 0), _white);
      expect(r.center(0, 3), _black);
      expect(r.center(3, 3), _black);
    });

    test('per-corner outer radii', () async {
      final r = await _render(
        const QrDesign(
          finderStyle: QrFinderStyle(
            outer: QrFinderPartStyle(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
        ),
      );
      expect(r.at(1, 1), _white);
      expect(r.at(68, 1), _black);
      expect(r.at(68, 68), _white);
      expect(r.at(1, 68), _black);
    });

    test('separator fills the light band around the finder', () async {
      final r = await _render(
        const QrDesign(
          backgroundColor: _blue,
          finderStyle: QrFinderStyle(
            separator: QrFinderPartStyle(color: _white),
          ),
        ),
      );
      expect(r.center(7, 3), _white);
      expect(r.center(3, 7), _white);
      expect(r.center(7, 7), _white);
      expect(r.center(7, 13), _white);
      expect(r.center(13, 7), _white);
      // The gap inside the finder keeps the background.
      expect(r.center(1, 1), _blue);
    });

    test('separator never spills into the quiet zone', () async {
      final r = await _render(
        const QrDesign(
          backgroundColor: _blue,
          finderStyle: QrFinderStyle(
            separator: QrFinderPartStyle(color: _yellow),
          ),
        ),
        quietZone: 2,
      );
      // Row/col -1 relative to the matrix lies in the quiet zone.
      expect(r.center(-1, 3, offset: 20), _blue);
      expect(r.center(3, -1, offset: 20), _blue);
      expect(r.center(7, 3, offset: 20), _yellow);
    });

    test('custom finder renderer replaces the default geometry', () async {
      final r = await _render(
        const QrDesign(
          finderStyle: QrFinderStyle(renderer: _DiamondEyeRenderer()),
        ),
      );
      // Diamond eye: center filled, eye corners empty.
      expect(r.center(3, 3), _black);
      expect(r.at(21, 21), _white);
      expect(r.center(0, 0), _black);
    });

    test('finder gradient spans the whole code', () async {
      final r = await _render(
        const QrDesign(
          finderStyle: QrFinderStyle(
            outer: QrFinderPartStyle(
              gradient: LinearGradient(colors: [_red, _blue]),
            ),
          ),
        ),
      );
      final left = r.center(0, 0);
      final right = r.center(0, 20);
      expect(left.r, greaterThan(left.b));
      expect(right.b, greaterThan(right.r));
    });
  });

  group('background renderer', () {
    test('replaces the background color', () async {
      final r = await _render(
        const QrDesign(
          backgroundColor: _blue,
          backgroundRenderer: FilledBackgroundRenderer(color: _yellow),
        ),
      );
      expect(r.center(1, 1), _yellow);
    });

    test('rounded background leaves the corners transparent', () async {
      final r = await _render(
        const QrDesign(
          backgroundRenderer: FilledBackgroundRenderer(
            color: _yellow,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        quietZone: 2,
      );
      expect(r.at(0, 0).a, 0);
      expect(r.at(125, 2), _yellow);
    });

    test('can skip the quiet zone', () async {
      final r = await _render(
        const QrDesign(
          backgroundRenderer: FilledBackgroundRenderer(
            color: _yellow,
            coverQuietZone: false,
          ),
        ),
        quietZone: 2,
      );
      expect(r.at(5, 5).a, 0);
      expect(r.center(1, 1, offset: 20), _yellow);
    });
  });
}
