import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../../core/models/qr_module_context.dart';
import '../../styles/qr_module_style.dart';

/// Geometry of one module, in canvas coordinates.
@immutable
class QrModuleGeometry {
  /// Creates module geometry.
  const QrModuleGeometry({
    required this.cellRect,
    required this.rect,
    required this.borderRadius,
    required this.context,
    required this.style,
  });

  /// The full grid cell occupied by the module.
  final Rect cellRect;

  /// The area the shape should fill: [cellRect] reduced by the style's
  /// spacing and scale.
  final Rect rect;

  /// Corner radii to use for [rect], already resolved: the style's
  /// `borderRadius` (or the shape's default), with smart-corner decisions
  /// applied when the style uses them. Not yet clamped to [rect].
  final BorderRadius borderRadius;

  /// Matrix information about the module.
  final QrModuleContext context;

  /// Resolved style for the module.
  final QrModuleStyle style;

  /// Side length of a grid cell in logical pixels.
  double get moduleExtent => cellRect.width;
}

/// Contract for drawing a single dark module.
///
/// Implementations return the module outline as a [Path]. The rendering
/// pipeline merges paths that share a style into a single fill, which avoids
/// hairline seams between touching modules. Rotation, color, opacity and
/// gradients are applied by the pipeline, so renderers only describe shape.
///
/// ```dart
/// class StarRenderer extends QrModuleRenderer {
///   const StarRenderer();
///
///   @override
///   Path buildPath(QrModuleGeometry geometry) {
///     final r = geometry.rect;
///     return Path()
///       ..moveTo(r.center.dx, r.top)
///       ..lineTo(r.right, r.center.dy)
///       ..lineTo(r.center.dx, r.bottom)
///       ..lineTo(r.left, r.center.dy)
///       ..close();
///   }
/// }
/// ```
abstract class QrModuleRenderer {
  /// Const constructor for subclasses.
  const QrModuleRenderer();

  /// Returns the outline of the module described by [geometry].
  Path buildPath(QrModuleGeometry geometry);
}
