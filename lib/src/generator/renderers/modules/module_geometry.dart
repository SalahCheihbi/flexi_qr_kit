import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import '../../../core/models/qr_module_context.dart';
import '../../styles/qr_module_shape.dart';
import '../../styles/qr_module_style.dart';
import 'built_in_module_renderers.dart';
import 'qr_module_renderer.dart';

/// Returns the area a module shape occupies inside [cell]: the cell reduced
/// by [QrModuleStyle.spacing], then scaled by [QrModuleStyle.scale] around
/// its center.
Rect resolveModuleRect(Rect cell, QrModuleStyle style) {
  final extent = cell.shortestSide;
  final spaced = math.max(extent - style.spacing, extent * 0.1);
  final side = spaced * style.scale;
  return Rect.fromCenter(center: cell.center, width: side, height: side);
}

/// Builds an [RRect] for [rect] with independent corner radii, clamping each
/// radius to `[0, rect.shortestSide / 2]` so corners never overlap.
RRect resolveModuleRRect(Rect rect, BorderRadius radius) {
  final max = rect.shortestSide / 2;
  Radius clamp(Radius r) =>
      Radius.elliptical(r.x.clamp(0.0, max), r.y.clamp(0.0, max));
  return RRect.fromRectAndCorners(
    rect,
    topLeft: clamp(radius.topLeft),
    topRight: clamp(radius.topRight),
    bottomRight: clamp(radius.bottomRight),
    bottomLeft: clamp(radius.bottomLeft),
  );
}

/// Returns the renderer used for a built-in [shape].
QrModuleRenderer builtInModuleRenderer(QrModuleShape shape) => switch (shape) {
  QrModuleShape.square => const SquareModuleRenderer(),
  QrModuleShape.rounded => const RoundedModuleRenderer(
    defaultRadiusFactor: 0.35,
  ),
  QrModuleShape.dots => const CircleModuleRenderer(diameterFactor: 0.8),
  QrModuleShape.circle => const CircleModuleRenderer(),
  QrModuleShape.diamond => const DiamondModuleRenderer(),
  QrModuleShape.custom => const RoundedModuleRenderer(),
};

/// Builds the final outline of one module in canvas coordinates: resolves
/// its rectangle, delegates the shape to the style's renderer and applies
/// rotation around the cell center.
Path buildModulePath(Rect cell, QrModuleContext context, QrModuleStyle style) {
  final renderer = style.renderer ?? builtInModuleRenderer(style.shape);
  final path = renderer.buildPath(
    QrModuleGeometry(
      cellRect: cell,
      rect: resolveModuleRect(cell, style),
      context: context,
      style: style,
    ),
  );
  if (style.rotation == 0) return path;
  return path.transform(_rotationAround(cell.center, style.rotation));
}

/// Column-major 4x4 matrix rotating by [angle] radians around [pivot].
Float64List _rotationAround(Offset pivot, double angle) {
  final c = math.cos(angle);
  final s = math.sin(angle);
  final tx = pivot.dx - c * pivot.dx + s * pivot.dy;
  final ty = pivot.dy - s * pivot.dx - c * pivot.dy;
  return Float64List.fromList([
    c, s, 0, 0, //
    -s, c, 0, 0, //
    0, 0, 1, 0, //
    tx, ty, 0, 1, //
  ]);
}
