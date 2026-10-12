import 'dart:ui' as ui;

import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _renderer = DefaultQrFinderRenderer();

QrFinderGeometry _geometry(QrFinderStyle style, {double extent = 10}) {
  return QrFinderGeometry(
    position: QrFinderPosition.topLeft,
    rect: Rect.fromLTWH(0, 0, 7 * extent, 7 * extent),
    separatorRect: Rect.fromLTWH(0, 0, 8 * extent, 8 * extent),
    moduleExtent: extent,
    style: style,
  );
}

/// Whether the outer frame covers the point [x] modules in from the left
/// edge, on the finder's middle row (10 px modules).
bool _frameAt(QrFinderStyle style, double x) =>
    _renderer.buildOuter(_geometry(style)).contains(Offset(x * 10, 35));

void main() {
  group('outerThickness', () {
    test('defaults to one module in safe mode', () {
      const s = QrFinderStyle();
      expect(s.outerThickness, 1);
      expect(s.safeMode, isTrue);
      expect(s.effectiveOuterThickness, 1);
      expect(_geometry(s).holeRect, const Rect.fromLTWH(10, 10, 50, 50));
    });

    test('rejects thickness outside (0, 2)', () {
      expect(() => QrFinderStyle(outerThickness: 0), throwsAssertionError);
      expect(() => QrFinderStyle(outerThickness: 2), throwsAssertionError);
    });

    test('safe mode keeps thickness within 0.8 to 1.2 modules', () {
      expect(
        const QrFinderStyle(outerThickness: 1.6).effectiveOuterThickness,
        1.2,
      );
      expect(
        const QrFinderStyle(outerThickness: 0.3).effectiveOuterThickness,
        0.8,
      );
      expect(
        const QrFinderStyle(outerThickness: 1.1).effectiveOuterThickness,
        1.1,
      );
    });

    test('advanced mode applies the requested thickness', () {
      const s = QrFinderStyle(outerThickness: 1.6, safeMode: false);
      expect(s.effectiveOuterThickness, 1.6);
      expect(_geometry(s).holeRect, const Rect.fromLTWH(16, 16, 38, 38));
    });

    test('a thicker frame covers more of the gap', () {
      const thick = QrFinderStyle(outerThickness: 1.2);
      expect(_frameAt(const QrFinderStyle(), 1.1), isFalse);
      expect(_frameAt(thick, 1.1), isTrue);
      expect(_frameAt(thick, 1.3), isFalse);
    });

    test('safe mode clamps while advanced mode does not', () {
      expect(_frameAt(const QrFinderStyle(outerThickness: 1.6), 1.5), isFalse);
      expect(
        _frameAt(
          const QrFinderStyle(outerThickness: 1.6, safeMode: false),
          1.5,
        ),
        isTrue,
      );
    });

    test('a thinner frame leaves a wider gap', () {
      const thin = QrFinderStyle(outerThickness: 0.5, safeMode: false);
      expect(_frameAt(thin, 0.4), isTrue);
      expect(_frameAt(thin, 0.6), isFalse);
    });

    test('the inner eye does not move with thickness', () {
      const s = QrFinderStyle(outerThickness: 1.6, safeMode: false);
      expect(_geometry(s).innerRect, const Rect.fromLTWH(20, 20, 30, 30));
    });

    test('rounded hole stays concentric with a thicker frame', () {
      // Outer radius 30, thickness 1.5 modules -> hole radius 15.
      const s = QrFinderStyle(
        outerThickness: 1.5,
        safeMode: false,
        outer: QrFinderPartStyle(
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
      );
      final path = _renderer.buildOuter(_geometry(s));
      // Hole corner at (15,15); radius 15 -> its corner area belongs to the
      // frame, its middle does not.
      expect(path.contains(const Offset(16, 16)), isTrue);
      expect(path.contains(const Offset(30, 30)), isFalse);
    });

    test('value equality includes thickness and mode', () {
      expect(
        const QrFinderStyle(outerThickness: 1.1),
        isNot(const QrFinderStyle()),
      );
      expect(
        const QrFinderStyle(safeMode: false),
        isNot(const QrFinderStyle()),
      );
      expect(
        const QrFinderStyle().copyWith(outerThickness: 1.1, safeMode: false),
        const QrFinderStyle(outerThickness: 1.1, safeMode: false),
      );
    });

    test('the pipeline renders the requested thickness', () async {
      // Version 1, no quiet zone, 210 px -> 10 px modules.
      final m = const QrPackageEncoder().encode('t', version: 1);
      final recorder = ui.PictureRecorder();
      QrRenderPipeline(
        matrix: m,
        design: const QrDesign(
          quietZone: 0,
          finderStyle: QrFinderStyle(outerThickness: 1.5, safeMode: false),
        ),
      ).paint(Canvas(recorder), const Size.square(210));
      final image = await recorder.endRecording().toImage(210, 210);
      final bytes = (await image.toByteData())!;
      int red(int x, int y) => bytes.getUint8((y * 210 + x) * 4);
      expect(red(13, 35), 0, reason: 'thick frame reaches 1.3 modules');
      expect(red(17, 35), 255, reason: 'gap starts after 1.5 modules');
      image.dispose();
    });
  });

  group('default finders', () {
    test('unstyled finders are standard solid finders in the module color', () {
      const design = QrDesign(
        moduleStyle: QrModuleStyle(
          shape: QrModuleShape.dots,
          color: Color(0xFF1A237E),
        ),
      );
      final s = design.effectiveFinderStyleFor(QrFinderPosition.topLeft)!;
      expect(s.outer.color, const Color(0xFF1A237E));
      expect(s.inner.color, const Color(0xFF1A237E));
      expect(s.outer.borderRadius, BorderRadius.zero);
      expect(s.effectiveOuterThickness, 1);
    });

    test('explicit styles win; styleFindersAsModules opts out', () {
      final rounded = QrFinderStyle.rounded();
      expect(
        QrDesign(
          finderStyle: rounded,
        ).effectiveFinderStyleFor(QrFinderPosition.topRight),
        rounded,
      );
      expect(
        const QrDesign(
          styleFindersAsModules: true,
        ).effectiveFinderStyleFor(QrFinderPosition.topRight),
        isNull,
      );
    });

    test('dots modules keep solid finder rings', () async {
      final m = const QrPackageEncoder().encode('t', version: 1);
      final recorder = ui.PictureRecorder();
      QrRenderPipeline(
        matrix: m,
        design: const QrDesign(
          quietZone: 0,
          moduleStyle: QrModuleStyle(shape: QrModuleShape.dots),
        ),
      ).paint(Canvas(recorder), const Size.square(210));
      final image = await recorder.endRecording().toImage(210, 210);
      final bytes = (await image.toByteData())!;
      int red(int x, int y) => bytes.getUint8((y * 210 + x) * 4);
      // Boundary between finder modules (0,0) and (0,1): a dot would leave
      // a gap here, the solid ring does not.
      expect(red(10, 5), 0);
      expect(red(1, 1), 0, reason: 'sharp outer corner');
      image.dispose();
    });
  });

  group('presets', () {
    test('square has sharp corners in one color', () {
      final s = QrFinderStyle.square(color: const Color(0xFF123456));
      expect(s.outer.borderRadius, BorderRadius.zero);
      expect(s.inner.borderRadius, BorderRadius.zero);
      expect(s.outer.color, const Color(0xFF123456));
      expect(s.inner.color, const Color(0xFF123456));
    });

    test('rounded applies the given radii', () {
      final s = QrFinderStyle.rounded(
        outerRadius: const Radius.circular(12),
        innerRadius: const Radius.circular(6),
      );
      expect(s.outer.borderRadius, const BorderRadius.all(Radius.circular(12)));
      expect(s.inner.borderRadius, const BorderRadius.all(Radius.circular(6)));
      expect(s.outer.color, const Color(0xFF000000));
    });

    test('rounded has scale-friendly defaults', () {
      final s = QrFinderStyle.rounded();
      expect(s.outer.borderRadius.topLeft.x, greaterThan(0));
      expect(s.inner.borderRadius.topLeft.x, greaterThan(0));
    });

    test('circle draws a round ring and a round eye', () {
      final g = _geometry(QrFinderStyle.circle());
      final outer = _renderer.buildOuter(g);
      final inner = _renderer.buildInner(g);
      expect(outer.contains(const Offset(35, 3)), isTrue, reason: 'ring top');
      expect(outer.contains(const Offset(3, 3)), isFalse, reason: 'corner');
      expect(outer.contains(const Offset(35, 35)), isFalse, reason: 'hole');
      expect(inner.contains(const Offset(35, 35)), isTrue);
      expect(inner.contains(const Offset(21, 21)), isFalse);
    });

    test('presets accept separate inner and outer colors', () {
      final s = QrFinderStyle.circle(
        color: const Color(0xFF111111),
        innerColor: const Color(0xFFFF0000),
      );
      expect(s.outer.color, const Color(0xFF111111));
      expect(s.inner.color, const Color(0xFFFF0000));
    });

    test('presets pass thickness and mode through', () {
      final s = QrFinderStyle.rounded(outerThickness: 1.2, safeMode: false);
      expect(s.outerThickness, 1.2);
      expect(s.safeMode, isFalse);
    });
  });
}
