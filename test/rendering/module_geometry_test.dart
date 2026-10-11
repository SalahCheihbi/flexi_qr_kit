import 'dart:math' as math;

import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _ctx = QrModuleContext(
  row: 0,
  col: 0,
  isDark: true,
  type: QrModuleType.data,
  neighbors: QrNeighbors(),
);

const _cell = Rect.fromLTWH(0, 0, 20, 20);

Path _build(QrModuleStyle style, {Rect cell = _cell}) =>
    buildModulePath(cell, _ctx, style);

/// Points just inside each corner of [r], in the order
/// topLeft, topRight, bottomRight, bottomLeft.
List<Offset> _cornerProbes(Rect r) => [
  r.topLeft + const Offset(0.3, 0.3),
  r.topRight + const Offset(-0.3, 0.3),
  r.bottomRight + const Offset(-0.3, -0.3),
  r.bottomLeft + const Offset(0.3, -0.3),
];

const _cornerNames = ['topLeft', 'topRight', 'bottomRight', 'bottomLeft'];

void main() {
  group('resolveModuleRect', () {
    test('fills the cell by default', () {
      expect(resolveModuleRect(_cell, const QrModuleStyle()), _cell);
    });

    test('scale shrinks around the cell center', () {
      expect(
        resolveModuleRect(_cell, const QrModuleStyle(scale: 0.5)),
        const Rect.fromLTWH(5, 5, 10, 10),
      );
    });

    test('spacing is removed before scale', () {
      expect(
        resolveModuleRect(_cell, const QrModuleStyle(spacing: 4, scale: 0.5)),
        const Rect.fromLTWH(6, 6, 8, 8),
      );
    });

    test('spacing never makes a module smaller than 10% of its cell', () {
      expect(
        resolveModuleRect(_cell, const QrModuleStyle(spacing: 100)).width,
        closeTo(2, 1e-9),
      );
    });
  });

  group('resolveModuleRRect', () {
    test('keeps every corner independent', () {
      final rr = resolveModuleRRect(
        _cell,
        const BorderRadius.only(
          topLeft: Radius.circular(1),
          topRight: Radius.circular(2),
          bottomRight: Radius.circular(3),
        ),
      );
      expect(rr.tlRadius, const Radius.circular(1));
      expect(rr.trRadius, const Radius.circular(2));
      expect(rr.brRadius, const Radius.circular(3));
      expect(rr.blRadius, Radius.zero);
    });

    test('clamps radii to half of the module', () {
      final rr = resolveModuleRRect(_cell, BorderRadius.circular(999));
      expect(rr.tlRadius, const Radius.circular(10));
      expect(rr.brRadius, const Radius.circular(10));
    });

    test('clamps negative radii to zero', () {
      final rr = resolveModuleRRect(
        _cell,
        const BorderRadius.only(topLeft: Radius.circular(-4)),
      );
      expect(rr.tlRadius, Radius.zero);
    });
  });

  group('custom shape: independent corners', () {
    // Every one of the 16 rounded/sharp combinations.
    for (var mask = 0; mask < 16; mask++) {
      final rounded = [for (var i = 0; i < 4; i++) mask & (1 << i) != 0];
      final label = [
        for (var i = 0; i < 4; i++)
          '${_cornerNames[i]}=${rounded[i] ? 'R' : 'S'}',
      ].join(' ');

      test(label, () {
        Radius r(int i) => rounded[i] ? const Radius.circular(8) : Radius.zero;
        final path = _build(
          QrModuleStyle(
            shape: QrModuleShape.custom,
            borderRadius: BorderRadius.only(
              topLeft: r(0),
              topRight: r(1),
              bottomRight: r(2),
              bottomLeft: r(3),
            ),
          ),
        );
        expect(path.contains(_cell.center), isTrue);
        final probes = _cornerProbes(_cell);
        for (var i = 0; i < 4; i++) {
          expect(
            path.contains(probes[i]),
            !rounded[i],
            reason:
                '${_cornerNames[i]} should be ${rounded[i] ? 'rounded' : 'sharp'}',
          );
        }
      });
    }

    test('only bottomLeft sharp (spec example)', () {
      final path = _build(
        const QrModuleStyle(
          shape: QrModuleShape.custom,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
            bottomLeft: Radius.zero,
          ),
        ),
      );
      final p = _cornerProbes(_cell);
      expect(path.contains(p[0]), isFalse);
      expect(path.contains(p[1]), isFalse);
      expect(path.contains(p[2]), isFalse);
      expect(path.contains(p[3]), isTrue);
    });

    test('custom without borderRadius is a sharp square', () {
      final path = _build(const QrModuleStyle(shape: QrModuleShape.custom));
      for (final p in _cornerProbes(_cell)) {
        expect(path.contains(p), isTrue);
      }
    });

    test('corner radii follow the scaled module, not the cell', () {
      final path = _build(
        const QrModuleStyle(
          shape: QrModuleShape.custom,
          scale: 0.5,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(999)),
        ),
      );
      final r = resolveModuleRect(_cell, const QrModuleStyle(scale: 0.5));
      final p = _cornerProbes(r);
      expect(path.contains(p[0]), isFalse);
      expect(path.contains(p[1]), isTrue);
      expect(path.contains(_cell.topLeft + const Offset(1, 1)), isFalse);
    });
  });

  group('built-in shapes', () {
    test('square covers the whole cell', () {
      final path = _build(const QrModuleStyle());
      for (final p in _cornerProbes(_cell)) {
        expect(path.contains(p), isTrue);
      }
    });

    test('rounded rounds all four corners by default', () {
      final path = _build(const QrModuleStyle(shape: QrModuleShape.rounded));
      expect(path.contains(_cell.center), isTrue);
      for (final p in _cornerProbes(_cell)) {
        expect(path.contains(p), isFalse);
      }
    });

    test('rounded honors explicit per-corner radii', () {
      final path = _build(
        const QrModuleStyle(
          shape: QrModuleShape.rounded,
          borderRadius: BorderRadius.only(topRight: Radius.circular(6)),
        ),
      );
      final p = _cornerProbes(_cell);
      expect(path.contains(p[0]), isTrue);
      expect(path.contains(p[1]), isFalse);
    });

    test('circle is inscribed in the module', () {
      final path = _build(const QrModuleStyle(shape: QrModuleShape.circle));
      expect(path.contains(_cell.center), isTrue);
      expect(path.contains(const Offset(0.5, 10)), isTrue);
      for (final p in _cornerProbes(_cell)) {
        expect(path.contains(p), isFalse);
      }
    });

    test('dots are smaller than the cell', () {
      final path = _build(const QrModuleStyle(shape: QrModuleShape.dots));
      expect(path.contains(_cell.center), isTrue);
      expect(path.contains(const Offset(1, 10)), isFalse);
      expect(path.getBounds().width, closeTo(16, 1e-6));
    });

    test('diamond touches edge midpoints, not corners', () {
      final path = _build(const QrModuleStyle(shape: QrModuleShape.diamond));
      expect(path.contains(_cell.center), isTrue);
      expect(path.contains(const Offset(10, 0.5)), isTrue);
      expect(path.contains(const Offset(0.5, 10)), isTrue);
      for (final p in _cornerProbes(_cell)) {
        expect(path.contains(p), isFalse);
      }
    });

    test('every shape is positioned in its own cell', () {
      const cell = Rect.fromLTWH(40, 60, 20, 20);
      for (final shape in QrModuleShape.values) {
        final b = _build(QrModuleStyle(shape: shape), cell: cell).getBounds();
        expect(
          cell.inflate(1e-6).contains(b.topLeft),
          isTrue,
          reason: '$shape',
        );
        expect(
          cell.inflate(1e-6).contains(b.bottomRight),
          isTrue,
          reason: '$shape',
        );
      }
    });
  });

  group('buildConcaveFillet', () {
    for (final corner in QrCorner.values) {
      test('fills only the outer sliver of the $corner corner', () {
        final path = buildConcaveFillet(_cell, corner, 8);
        final i = corner.index;
        final probe = _cornerProbes(_cell)[i];
        // Point inside the quarter circle (0.5r from the corner diagonally).
        final inward = switch (corner) {
          QrCorner.topLeft => const Offset(4, 4),
          QrCorner.topRight => const Offset(16, 4),
          QrCorner.bottomRight => const Offset(16, 16),
          QrCorner.bottomLeft => const Offset(4, 16),
        };
        expect(path.contains(probe), isTrue, reason: 'corner sliver filled');
        expect(path.contains(inward), isFalse, reason: 'arc is concave');
        expect(path.contains(_cell.center), isFalse);
        expect(_cell.inflate(1e-6).contains(path.getBounds().topLeft), isTrue);
        expect(
          _cell.inflate(1e-6).contains(path.getBounds().bottomRight),
          isTrue,
        );
      });
    }

    test('clamps the radius to half the cell', () {
      final b = buildConcaveFillet(_cell, QrCorner.topLeft, 999).getBounds();
      expect(b.width, closeTo(10, 1e-6));
    });
  });

  group('rotation', () {
    test('rotates the shape around the cell center', () {
      final path = _build(const QrModuleStyle(rotation: math.pi / 4));
      expect(path.contains(_cell.center), isTrue);
      // The rotated square's vertex pokes out above the cell top edge.
      expect(path.getBounds().top, lessThan(_cell.top));
      expect(path.contains(const Offset(10, 0.5)), isTrue);
      expect(path.contains(_cornerProbes(_cell)[0]), isFalse);
    });

    test('a full turn is a no-op', () {
      final b = _build(const QrModuleStyle(rotation: 2 * math.pi)).getBounds();
      expect(b.left, closeTo(0, 1e-9));
      expect(b.right, closeTo(20, 1e-9));
    });
  });

  group('custom renderer', () {
    test('replaces the built-in shape', () {
      final path = _build(
        const QrModuleStyle(
          shape: QrModuleShape.square,
          renderer: _TriangleRenderer(),
        ),
      );
      expect(path.contains(const Offset(10, 15)), isTrue);
      expect(path.contains(_cornerProbes(_cell)[0]), isFalse);
    });

    test('receives geometry and module context', () {
      final spy = _SpyRenderer();
      buildModulePath(_cell, _ctx, QrModuleStyle(renderer: spy, scale: 0.5));
      final g = spy.received!;
      expect(g.cellRect, _cell);
      expect(g.rect, const Rect.fromLTWH(5, 5, 10, 10));
      expect(g.moduleExtent, 20);
      expect(g.context, _ctx);
    });
  });
}

class _TriangleRenderer extends QrModuleRenderer {
  const _TriangleRenderer();

  @override
  Path buildPath(QrModuleGeometry geometry) {
    final r = geometry.rect;
    return Path()
      ..moveTo(r.center.dx, r.top)
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..close();
  }
}

class _SpyRenderer extends QrModuleRenderer {
  QrModuleGeometry? received;

  @override
  Path buildPath(QrModuleGeometry geometry) {
    received = geometry;
    return Path()..addRect(geometry.rect);
  }
}
