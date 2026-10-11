import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _engine = QrSmartCornerEngine();

QrNeighbors _orthogonal(int mask) => QrNeighbors(
  top: mask & 1 != 0,
  right: mask & 2 != 0,
  bottom: mask & 4 != 0,
  left: mask & 8 != 0,
);

void main() {
  group('exposedCorners', () {
    test('an isolated module exposes all four corners', () {
      expect(
        _engine.exposedCorners(const QrNeighbors()),
        QrCorner.values.toSet(),
      );
    });

    test('a module inside a run exposes no corner', () {
      expect(
        _engine.exposedCorners(
          const QrNeighbors(top: true, bottom: true, left: true, right: true),
        ),
        isEmpty,
      );
    });

    test('the end of a horizontal run exposes its two outer corners', () {
      expect(_engine.exposedCorners(const QrNeighbors(right: true)), {
        QrCorner.topLeft,
        QrCorner.bottomLeft,
      });
    });

    // All 16 orthogonal neighbor layouts: a corner is exposed iff both
    // neighbors sharing it are light.
    for (var mask = 0; mask < 16; mask++) {
      final n = _orthogonal(mask);
      test('orthogonal layout $mask', () {
        expect(_engine.exposedCorners(n), {
          if (!n.top && !n.left) QrCorner.topLeft,
          if (!n.top && !n.right) QrCorner.topRight,
          if (!n.bottom && !n.right) QrCorner.bottomRight,
          if (!n.bottom && !n.left) QrCorner.bottomLeft,
        });
      });
    }

    test('diagonal-only contact still rounds to avoid a pinch point', () {
      expect(
        _engine.exposedCorners(
          const QrNeighbors(
            topLeft: true,
            topRight: true,
            bottomLeft: true,
            bottomRight: true,
          ),
        ),
        QrCorner.values.toSet(),
      );
    });
  });

  group('concaveCorners', () {
    test('requires both orthogonal neighbors and the diagonal', () {
      expect(
        _engine.concaveCorners(
          const QrNeighbors(top: true, left: true, topLeft: true),
        ),
        {QrCorner.topLeft},
      );
    });

    test('is empty when the diagonal is light', () {
      expect(
        _engine.concaveCorners(const QrNeighbors(top: true, left: true)),
        isEmpty,
      );
    });

    test('is empty with a single orthogonal neighbor', () {
      expect(
        _engine.concaveCorners(const QrNeighbors(top: true, topLeft: true)),
        isEmpty,
      );
    });

    test('detects every corner of a fully surrounded hole', () {
      expect(
        _engine.concaveCorners(
          const QrNeighbors(
            top: true,
            bottom: true,
            left: true,
            right: true,
            topLeft: true,
            topRight: true,
            bottomLeft: true,
            bottomRight: true,
          ),
        ),
        QrCorner.values.toSet(),
      );
    });
  });

  group('resolve', () {
    const base = BorderRadius.only(
      topLeft: Radius.circular(1),
      topRight: Radius.circular(2),
      bottomRight: Radius.circular(3),
      bottomLeft: Radius.circular(4),
    );

    test('keeps each base radius on exposed corners', () {
      expect(_engine.resolve(const QrNeighbors(), base), base);
    });

    test('sharpens corners touching a neighbor', () {
      expect(
        _engine.resolve(const QrNeighbors(bottom: true), base),
        const BorderRadius.only(
          topLeft: Radius.circular(1),
          topRight: Radius.circular(2),
        ),
      );
    });

    test('never rounds a corner the base leaves sharp', () {
      expect(
        _engine.resolve(
          const QrNeighbors(),
          const BorderRadius.only(topLeft: Radius.circular(5)),
        ),
        const BorderRadius.only(topLeft: Radius.circular(5)),
      );
    });
  });
}
