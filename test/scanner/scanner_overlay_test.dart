import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _layout = Size(400, 800);

double _length(Path path) =>
    path.computeMetrics().fold(0, (sum, m) => sum + m.length);

void main() {
  group('QrScannerOverlayStyle.scanWindowFor', () {
    test('centers the window by default', () {
      const style = QrScannerOverlayStyle(windowSize: Size(200, 200));
      expect(
        style.scanWindowFor(_layout),
        const Rect.fromLTWH(100, 300, 200, 200),
      );
    });

    test('follows the alignment', () {
      const style = QrScannerOverlayStyle(
        windowSize: Size(200, 200),
        alignment: Alignment.topLeft,
      );
      expect(style.scanWindowFor(_layout), const Rect.fromLTWH(0, 0, 200, 200));
    });

    test('shrinks the window to fit a smaller layout', () {
      const style = QrScannerOverlayStyle(windowSize: Size(300, 300));
      expect(
        style.scanWindowFor(const Size(200, 100)),
        const Rect.fromLTWH(0, 0, 200, 100),
      );
    });
  });

  group('QrScannerOverlayPainter.dimPath', () {
    const style = QrScannerOverlayStyle(windowSize: Size(200, 200));
    const painter = QrScannerOverlayPainter(style: style);
    final path = painter.dimPath(_layout);

    test('covers the area outside the window', () {
      expect(path.contains(const Offset(10, 10)), isTrue);
      expect(path.contains(const Offset(390, 790)), isTrue);
    });

    test('leaves the window clear', () {
      expect(path.contains(const Offset(200, 400)), isFalse);
      expect(path.contains(const Offset(105, 305)), isFalse);
    });

    test('follows independent corner radii of the window', () {
      const rounded = QrScannerOverlayPainter(
        style: QrScannerOverlayStyle(
          windowSize: Size(200, 200),
          frame: QrScannerFrameStyle(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(40)),
          ),
        ),
      );
      final p = rounded.dimPath(_layout);
      // Just inside the top-left corner is dimmed by the rounding...
      expect(p.contains(const Offset(102, 302)), isTrue);
      // ...while the sharp top-right corner stays clear.
      expect(p.contains(const Offset(298, 302)), isFalse);
    });
  });

  group('QrScannerOverlayPainter.framePath', () {
    const window = Rect.fromLTWH(0, 0, 200, 200);

    test('draws one bracket per corner with the given length', () {
      const painter = QrScannerOverlayPainter(
        style: QrScannerOverlayStyle(
          frame: QrScannerFrameStyle(
            cornerLength: 30,
            borderRadius: BorderRadius.zero,
          ),
        ),
      );
      final path = painter.framePath(window);
      expect(path.computeMetrics().length, 4);
      expect(_length(path), closeTo(4 * 2 * 30, 0.01));
    });

    test('only draws the requested corners', () {
      const painter = QrScannerOverlayPainter(
        style: QrScannerOverlayStyle(
          frame: QrScannerFrameStyle(
            cornerLength: 30,
            corners: {QrCorner.topLeft, QrCorner.bottomRight},
          ),
        ),
      );
      final path = painter.framePath(window);
      expect(path.computeMetrics().length, 2);
      expect(path.getBounds(), window);
    });

    test('rounds each bracket by its own radius', () {
      const painter = QrScannerOverlayPainter(
        style: QrScannerOverlayStyle(
          frame: QrScannerFrameStyle(
            cornerLength: 30,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
            corners: {QrCorner.topLeft},
          ),
        ),
      );
      // Two 10 px straight legs plus a quarter circle of radius 20.
      expect(
        _length(painter.framePath(window)),
        closeTo(2 * 10 + 3.14159265 * 20 / 2, 0.5),
      );
    });

    test('a bracket never runs past half the window side', () {
      const painter = QrScannerOverlayPainter(
        style: QrScannerOverlayStyle(
          frame: QrScannerFrameStyle(
            cornerLength: 500,
            borderRadius: BorderRadius.zero,
            corners: {QrCorner.topLeft},
          ),
        ),
      );
      expect(_length(painter.framePath(window)), closeTo(2 * 100, 0.01));
    });

    test('a full border traces the whole rounded window', () {
      const painter = QrScannerOverlayPainter(
        style: QrScannerOverlayStyle(
          frame: QrScannerFrameStyle(
            fullBorder: true,
            borderRadius: BorderRadius.zero,
          ),
        ),
      );
      expect(_length(painter.framePath(window)), closeTo(800, 0.01));
    });
  });

  test('repaints only when the style changes', () {
    const a = QrScannerOverlayPainter(style: QrScannerOverlayStyle());
    const b = QrScannerOverlayPainter(style: QrScannerOverlayStyle());
    const c = QrScannerOverlayPainter(
      style: QrScannerOverlayStyle(overlayColor: Color(0x00000000)),
    );
    expect(a.shouldRepaint(b), isFalse);
    expect(a.shouldRepaint(c), isTrue);
  });

  test('frame style copyWith replaces only given fields', () {
    const s = QrScannerFrameStyle();
    final copy = s.copyWith(strokeWidth: 8);
    expect(copy.strokeWidth, 8);
    expect(copy.color, s.color);
    expect(copy.borderRadius, s.borderRadius);
  });
}
