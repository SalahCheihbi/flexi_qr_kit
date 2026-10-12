import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import '../../../core/models/qr_corner.dart';
import '../../../core/models/qr_module_context.dart';
import '../../smart_corners/qr_smart_corner_engine.dart';
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
  QrModuleShape.rounded ||
  QrModuleShape.connected ||
  QrModuleShape.smooth ||
  QrModuleShape.custom => const RoundedModuleRenderer(),
  QrModuleShape.dots => const CircleModuleRenderer(diameterFactor: 0.8),
  QrModuleShape.circle => const CircleModuleRenderer(),
  QrModuleShape.diamond => const DiamondModuleRenderer(),
};

/// Corner radii a [shape] uses on [rect] when the style sets no
/// `borderRadius`: 35% of the side for [QrModuleShape.rounded], 50% for
/// [QrModuleShape.connected] and [QrModuleShape.smooth], sharp otherwise.
BorderRadius defaultModuleRadius(QrModuleShape shape, Rect rect) {
  final factor = switch (shape) {
    QrModuleShape.rounded => 0.35,
    QrModuleShape.connected || QrModuleShape.smooth => 0.5,
    _ => 0.0,
  };
  return BorderRadius.circular(rect.shortestSide * factor);
}

/// Builds the final outline of one module in canvas coordinates: resolves
/// its rectangle and corner radii (applying [engine] when the style uses
/// smart corners), delegates the shape to the style's renderer and applies
/// rotation around the cell center.
Path buildModulePath(
  Rect cell,
  QrModuleContext context,
  QrModuleStyle style, {
  QrSmartCornerEngine engine = const QrSmartCornerEngine(),
}) {
  final rect = resolveModuleRect(cell, style);
  final base = style.borderRadius ?? defaultModuleRadius(style.shape, rect);
  final radius = style.usesSmartCorners
      ? engine.resolve(context.neighbors, base)
      : base;

  // An explicit borderRadius on the default square shape is honored.
  final renderer =
      style.renderer ??
      (style.shape == QrModuleShape.square && style.borderRadius != null
          ? const RoundedModuleRenderer()
          : builtInModuleRenderer(style.shape));
  final path = renderer.buildPath(
    QrModuleGeometry(
      cellRect: cell,
      rect: rect,
      borderRadius: radius,
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

/// Concave fillet filling [corner] of a light [cell] with a quarter-circle
/// cut-out of [radius], used to smooth the inside of L-shaped junctions.
Path buildConcaveFillet(Rect cell, QrCorner corner, double radius) {
  final r = radius.clamp(0.0, cell.shortestSide / 2);
  // Corner point and the unit directions pointing into the cell.
  final (Offset p, double dx, double dy) = switch (corner) {
    QrCorner.topLeft => (cell.topLeft, 1, 1),
    QrCorner.topRight => (cell.topRight, -1, 1),
    QrCorner.bottomRight => (cell.bottomRight, -1, -1),
    QrCorner.bottomLeft => (cell.bottomLeft, 1, -1),
  };
  final start = p.translate(dx * r, 0);
  final end = p.translate(0, dy * r);
  // The arc bulges towards the corner point; its direction depends on the
  // orientation of the corner.
  final clockwise = (dx * dy) < 0;
  return Path()
    ..moveTo(p.dx, p.dy)
    ..lineTo(start.dx, start.dy)
    ..arcToPoint(end, radius: Radius.circular(r), clockwise: clockwise)
    ..close();
}
