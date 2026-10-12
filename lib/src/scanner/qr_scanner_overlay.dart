import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/models/qr_corner.dart';
import 'qr_scanner_overlay_style.dart';

/// Dims the camera preview outside the scan window and frames the window.
///
/// [FlexiQrScanner] adds it automatically; use it directly to put the same
/// overlay over your own camera preview.
class QrScannerOverlay extends StatelessWidget {
  /// Creates a scanner overlay.
  const QrScannerOverlay({
    super.key,
    this.style = const QrScannerOverlayStyle(),
  });

  /// Look and placement of the overlay.
  final QrScannerOverlayStyle style;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(painter: QrScannerOverlayPainter(style: style)),
      ),
    );
  }
}

/// Paints a [QrScannerOverlayStyle].
class QrScannerOverlayPainter extends CustomPainter {
  /// Creates an overlay painter.
  const QrScannerOverlayPainter({required this.style});

  /// Look and placement of the overlay.
  final QrScannerOverlayStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(dimPath(size), Paint()..color = style.overlayColor);

    final frame = style.frame;
    if (frame.strokeWidth > 0) {
      canvas.drawPath(
        framePath(style.scanWindowFor(size)),
        Paint()
          ..color = frame.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = frame.strokeWidth
          ..strokeCap = frame.strokeCap
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  /// Area of a preview of [size] outside the rounded scan window.
  Path dimPath(Size size) {
    final window = style.scanWindowFor(size);
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(_windowRRect(window));
  }

  /// Outline of the frame around [window], to be stroked.
  Path framePath(Rect window) {
    final frame = style.frame;
    if (frame.fullBorder) return Path()..addRRect(_windowRRect(window));

    final path = Path();
    for (final corner in QrCorner.values) {
      if (frame.corners.contains(corner)) _addBracket(path, window, corner);
    }
    return path;
  }

  /// Adds the bracket at [corner], traced clockwise: from the vertical or
  /// horizontal leg [a], around the rounded corner, out along leg [b].
  void _addBracket(Path path, Rect window, QrCorner corner) {
    final (Offset origin, Offset a, Offset b) = switch (corner) {
      QrCorner.topLeft => (
        window.topLeft,
        const Offset(0, 1),
        const Offset(1, 0),
      ),
      QrCorner.topRight => (
        window.topRight,
        const Offset(-1, 0),
        const Offset(0, 1),
      ),
      QrCorner.bottomRight => (
        window.bottomRight,
        const Offset(0, -1),
        const Offset(-1, 0),
      ),
      QrCorner.bottomLeft => (
        window.bottomLeft,
        const Offset(1, 0),
        const Offset(0, -1),
      ),
    };
    final radius = _radius(window, corner);
    final halfW = window.width / 2;
    final halfH = window.height / 2;
    final legX = style.frame.cornerLength.clamp(radius.x, halfW);
    final legY = style.frame.cornerLength.clamp(radius.y, halfH);

    // Each leg runs along one axis, so its extents come from that axis.
    double along(Offset dir, double x, double y) => dir.dx != 0 ? x : y;
    final aLeg = along(a, legX, legY);
    final aRadius = along(a, radius.x, radius.y);
    final bLeg = along(b, legX, legY);
    final bRadius = along(b, radius.x, radius.y);

    path
      ..moveTo(origin.dx + a.dx * aLeg, origin.dy + a.dy * aLeg)
      ..lineTo(origin.dx + a.dx * aRadius, origin.dy + a.dy * aRadius)
      // A zero radius draws a straight line to the sharp corner.
      ..arcToPoint(origin + b * bRadius, radius: radius)
      ..lineTo(origin.dx + b.dx * bLeg, origin.dy + b.dy * bLeg);
  }

  RRect _windowRRect(Rect window) => RRect.fromRectAndCorners(
    window,
    topLeft: _radius(window, QrCorner.topLeft),
    topRight: _radius(window, QrCorner.topRight),
    bottomRight: _radius(window, QrCorner.bottomRight),
    bottomLeft: _radius(window, QrCorner.bottomLeft),
  );

  /// Radius of [corner], clamped to half the window side.
  Radius _radius(Rect window, QrCorner corner) {
    final r = switch (corner) {
      QrCorner.topLeft => style.frame.borderRadius.topLeft,
      QrCorner.topRight => style.frame.borderRadius.topRight,
      QrCorner.bottomRight => style.frame.borderRadius.bottomRight,
      QrCorner.bottomLeft => style.frame.borderRadius.bottomLeft,
    };
    return Radius.elliptical(
      math.min(r.x, window.width / 2),
      math.min(r.y, window.height / 2),
    );
  }

  @override
  bool shouldRepaint(QrScannerOverlayPainter oldDelegate) =>
      oldDelegate.style != style;
}
