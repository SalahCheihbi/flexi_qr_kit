import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../../core/models/qr_finder_position.dart';
import '../../styles/qr_finder_style.dart';
import '../modules/module_geometry.dart';

/// Geometry of one finder pattern, in canvas coordinates.
@immutable
class QrFinderGeometry {
  /// Creates finder geometry.
  const QrFinderGeometry({
    required this.position,
    required this.rect,
    required this.separatorRect,
    required this.moduleExtent,
    required this.style,
  });

  /// Which finder is being drawn.
  final QrFinderPosition position;

  /// The 7x7 area of the finder.
  final Rect rect;

  /// [rect] grown by one module, clipped to the symbol (quiet zone
  /// excluded).
  final Rect separatorRect;

  /// Side length of one module.
  final double moduleExtent;

  /// Resolved style for this finder.
  final QrFinderStyle style;

  /// Drawn thickness of the outer frame in logical pixels
  /// (`style.effectiveOuterThickness` modules).
  double get outerThickness => style.effectiveOuterThickness * moduleExtent;

  /// The light area inside the frame: 5x5 modules at the standard
  /// thickness, adjusted by [outerThickness] otherwise.
  Rect get holeRect => rect.deflate(outerThickness);

  /// The 3x3 eye.
  Rect get innerRect => rect.deflate(2 * moduleExtent);
}

/// Contract for drawing a finder pattern as paths.
///
/// Each part is filled with its own [QrFinderPartStyle], so renderers only
/// describe shape. Extend [DefaultQrFinderRenderer] to replace a single
/// part.
abstract class QrFinderRenderer {
  /// Const constructor for subclasses.
  const QrFinderRenderer();

  /// Outline of the 7x7 frame, hole excluded.
  Path buildOuter(QrFinderGeometry geometry);

  /// Outline of the 3x3 eye.
  Path buildInner(QrFinderGeometry geometry);

  /// Outline of the light band around the finder. Only called when the
  /// style has a separator.
  Path buildSeparator(QrFinderGeometry geometry);
}

/// Rounded rectangles following each part's `borderRadius`.
class DefaultQrFinderRenderer extends QrFinderRenderer {
  /// Creates the default finder renderer.
  const DefaultQrFinderRenderer();

  @override
  Path buildOuter(QrFinderGeometry geometry) {
    final outer = _outerRRect(geometry);
    final e = geometry.outerThickness;
    Radius shrink(Radius r) =>
        Radius.elliptical(math.max(0, r.x - e), math.max(0, r.y - e));
    final hole = RRect.fromRectAndCorners(
      geometry.holeRect,
      topLeft: shrink(outer.tlRadius),
      topRight: shrink(outer.trRadius),
      bottomRight: shrink(outer.brRadius),
      bottomLeft: shrink(outer.blRadius),
    );
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(outer)
      ..addRRect(hole);
  }

  @override
  Path buildInner(QrFinderGeometry geometry) => Path()
    ..addRRect(
      resolveModuleRRect(geometry.innerRect, geometry.style.inner.borderRadius),
    );

  @override
  Path buildSeparator(QrFinderGeometry geometry) {
    final radius = geometry.style.separator?.borderRadius ?? BorderRadius.zero;
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(resolveModuleRRect(geometry.separatorRect, radius))
      ..addRRect(_outerRRect(geometry));
  }

  RRect _outerRRect(QrFinderGeometry geometry) =>
      resolveModuleRRect(geometry.rect, geometry.style.outer.borderRadius);
}
