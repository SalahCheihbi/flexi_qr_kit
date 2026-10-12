import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../core/models/qr_corner.dart';

/// Look of the frame drawn around the scan window.
///
/// By default the frame is four corner brackets. Each corner has its own
/// radius through [borderRadius], and [corners] picks which brackets are
/// drawn. Set [fullBorder] to outline the whole window instead.
@immutable
class QrScannerFrameStyle {
  /// Creates a frame style.
  const QrScannerFrameStyle({
    this.color = const Color(0xFFFFFFFF),
    this.strokeWidth = 4,
    this.cornerLength = 32,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.corners = const {
      QrCorner.topLeft,
      QrCorner.topRight,
      QrCorner.bottomRight,
      QrCorner.bottomLeft,
    },
    this.strokeCap = StrokeCap.round,
    this.fullBorder = false,
  }) : assert(strokeWidth >= 0, 'strokeWidth must not be negative'),
       assert(cornerLength >= 0, 'cornerLength must not be negative');

  /// Stroke color.
  final Color color;

  /// Stroke width in logical pixels. Zero hides the frame.
  final double strokeWidth;

  /// Length of each bracket leg, measured from the window corner along the
  /// edge. Never shorter than the corner radius nor longer than half the
  /// window side.
  final double cornerLength;

  /// Independent radius of each window corner. Also rounds the clear area
  /// of the dimmed overlay.
  final BorderRadius borderRadius;

  /// Corners that get a bracket. Ignored when [fullBorder] is set.
  final Set<QrCorner> corners;

  /// Shape of the bracket ends.
  final StrokeCap strokeCap;

  /// Outline the whole window instead of drawing corner brackets.
  final bool fullBorder;

  /// Returns a copy with the given fields replaced.
  QrScannerFrameStyle copyWith({
    Color? color,
    double? strokeWidth,
    double? cornerLength,
    BorderRadius? borderRadius,
    Set<QrCorner>? corners,
    StrokeCap? strokeCap,
    bool? fullBorder,
  }) {
    return QrScannerFrameStyle(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      cornerLength: cornerLength ?? this.cornerLength,
      borderRadius: borderRadius ?? this.borderRadius,
      corners: corners ?? this.corners,
      strokeCap: strokeCap ?? this.strokeCap,
      fullBorder: fullBorder ?? this.fullBorder,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QrScannerFrameStyle &&
      other.color == color &&
      other.strokeWidth == strokeWidth &&
      other.cornerLength == cornerLength &&
      other.borderRadius == borderRadius &&
      setEquals(other.corners, corners) &&
      other.strokeCap == strokeCap &&
      other.fullBorder == fullBorder;

  @override
  int get hashCode => Object.hash(
    color,
    strokeWidth,
    cornerLength,
    borderRadius,
    Object.hashAllUnordered(corners),
    strokeCap,
    fullBorder,
  );
}

/// Look and placement of the scanner overlay: a dimmed backdrop with a
/// clear scan window and a frame around it.
@immutable
class QrScannerOverlayStyle {
  /// Creates an overlay style.
  const QrScannerOverlayStyle({
    this.windowSize = const Size(260, 260),
    this.alignment = Alignment.center,
    this.overlayColor = const Color(0x99000000),
    this.frame = const QrScannerFrameStyle(),
  });

  /// Size of the scan window, shrunk to fit the preview when larger.
  final Size windowSize;

  /// Position of the scan window within the preview.
  final Alignment alignment;

  /// Color dimming the preview outside the window.
  final Color overlayColor;

  /// Frame drawn around the window.
  final QrScannerFrameStyle frame;

  /// Scan window rectangle within a preview of [layout] size.
  Rect scanWindowFor(Size layout) {
    final size = Size(
      windowSize.width.clamp(0, layout.width),
      windowSize.height.clamp(0, layout.height),
    );
    return alignment.inscribe(size, Offset.zero & layout);
  }

  /// Returns a copy with the given fields replaced.
  QrScannerOverlayStyle copyWith({
    Size? windowSize,
    Alignment? alignment,
    Color? overlayColor,
    QrScannerFrameStyle? frame,
  }) {
    return QrScannerOverlayStyle(
      windowSize: windowSize ?? this.windowSize,
      alignment: alignment ?? this.alignment,
      overlayColor: overlayColor ?? this.overlayColor,
      frame: frame ?? this.frame,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QrScannerOverlayStyle &&
      other.windowSize == windowSize &&
      other.alignment == alignment &&
      other.overlayColor == overlayColor &&
      other.frame == frame;

  @override
  int get hashCode => Object.hash(windowSize, alignment, overlayColor, frame);
}
