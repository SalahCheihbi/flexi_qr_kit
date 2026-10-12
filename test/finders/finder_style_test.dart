import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

QrFinderGeometry _geometry({
  QrFinderStyle style = const QrFinderStyle(),
  double extent = 10,
}) {
  final rect = Rect.fromLTWH(0, 0, 7 * extent, 7 * extent);
  return QrFinderGeometry(
    position: QrFinderPosition.topLeft,
    rect: rect,
    separatorRect: Rect.fromLTWH(0, 0, 8 * extent, 8 * extent),
    moduleExtent: extent,
    style: style,
  );
}

void main() {
  group('QrFinderPosition', () {
    test('origin of each finder in a 21x21 symbol', () {
      expect(QrFinderPosition.topLeft.origin(21), (0, 0));
      expect(QrFinderPosition.topRight.origin(21), (0, 14));
      expect(QrFinderPosition.bottomLeft.origin(21), (14, 0));
    });

    test('at() locates finder modules and ignores the rest', () {
      expect(QrFinderPosition.at(0, 0, 21), QrFinderPosition.topLeft);
      expect(QrFinderPosition.at(6, 6, 21), QrFinderPosition.topLeft);
      expect(QrFinderPosition.at(3, 17, 21), QrFinderPosition.topRight);
      expect(QrFinderPosition.at(20, 6, 21), QrFinderPosition.bottomLeft);
      expect(QrFinderPosition.at(7, 7, 21), isNull);
      expect(QrFinderPosition.at(10, 10, 21), isNull);
      expect(QrFinderPosition.at(20, 20, 21), isNull);
    });
  });

  group('QrFinderStyle', () {
    test('value equality and copyWith', () {
      const a = QrFinderStyle(
        outer: QrFinderPartStyle(color: Color(0xFFFF0000)),
      );
      const b = QrFinderStyle(
        outer: QrFinderPartStyle(color: Color(0xFFFF0000)),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);

      const inner = QrFinderPartStyle(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      );
      final c = a.copyWith(inner: inner);
      expect(c.inner, inner);
      expect(c.outer, a.outer);
      expect(c, isNot(a));
    });

    test('QrDesign resolves per-position overrides over finderStyle', () {
      const all = QrFinderStyle(
        outer: QrFinderPartStyle(color: Color(0xFF00FF00)),
      );
      const tl = QrFinderStyle(
        outer: QrFinderPartStyle(color: Color(0xFFFF0000)),
      );
      const design = QrDesign(finderStyle: all, topLeftFinderStyle: tl);
      expect(design.finderStyleFor(QrFinderPosition.topLeft), tl);
      expect(design.finderStyleFor(QrFinderPosition.topRight), all);
      expect(design.finderStyleFor(QrFinderPosition.bottomLeft), all);
      expect(const QrDesign().finderStyleFor(QrFinderPosition.topLeft), isNull);
    });
  });

  group('QrFinderGeometry', () {
    test('derives hole and inner eye rects from the module extent', () {
      final g = _geometry();
      expect(g.holeRect, const Rect.fromLTWH(10, 10, 50, 50));
      expect(g.innerRect, const Rect.fromLTWH(20, 20, 30, 30));
    });
  });

  group('DefaultQrFinderRenderer', () {
    const renderer = DefaultQrFinderRenderer();

    test('sharp outer ring covers the frame but not the hole', () {
      final path = renderer.buildOuter(_geometry());
      expect(path.contains(const Offset(1, 1)), isTrue);
      expect(path.contains(const Offset(35, 5)), isTrue);
      expect(path.contains(const Offset(69, 69)), isTrue);
      expect(path.contains(const Offset(35, 35)), isFalse);
      expect(path.contains(const Offset(15, 15)), isFalse);
    });

    test('rounds each outer corner independently', () {
      final path = renderer.buildOuter(
        _geometry(
          style: const QrFinderStyle(
            outer: QrFinderPartStyle(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(999)),
            ),
          ),
        ),
      );
      expect(path.contains(const Offset(1, 1)), isFalse);
      expect(path.contains(const Offset(69, 1)), isTrue);
      expect(path.contains(const Offset(69, 69)), isTrue);
      expect(path.contains(const Offset(1, 69)), isTrue);
    });

    test('hole corners stay concentric with the outer corners', () {
      final path = renderer.buildOuter(
        _geometry(
          style: const QrFinderStyle(
            outer: QrFinderPartStyle(
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
          ),
        ),
      );
      // The hole is rounded with radius 20, so its corner area belongs to
      // the ring.
      expect(path.contains(const Offset(11, 11)), isTrue);
      expect(path.contains(const Offset(35, 35)), isFalse);
    });

    test('inner eye fills the central 3x3 area', () {
      final sharp = renderer.buildInner(_geometry());
      expect(sharp.contains(const Offset(21, 21)), isTrue);
      expect(sharp.contains(const Offset(35, 35)), isTrue);
      expect(sharp.contains(const Offset(15, 15)), isFalse);

      final round = renderer.buildInner(
        _geometry(
          style: const QrFinderStyle(
            inner: QrFinderPartStyle(
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ),
        ),
      );
      expect(round.contains(const Offset(21, 21)), isFalse);
      expect(round.contains(const Offset(35, 35)), isTrue);
    });

    test('separator covers the band around the finder only', () {
      final path = renderer.buildSeparator(
        _geometry(style: const QrFinderStyle(separator: QrFinderPartStyle())),
      );
      expect(path.contains(const Offset(75, 35)), isTrue);
      expect(path.contains(const Offset(35, 75)), isTrue);
      expect(path.contains(const Offset(75, 75)), isTrue);
      expect(path.contains(const Offset(35, 35)), isFalse);
      expect(path.contains(const Offset(5, 5)), isFalse);
    });
  });
}
