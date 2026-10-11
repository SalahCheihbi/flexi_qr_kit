import 'package:flutter/painting.dart';

import 'module_geometry.dart';
import 'qr_module_renderer.dart';

/// Fills the module rectangle.
class SquareModuleRenderer extends QrModuleRenderer {
  /// Creates a square renderer.
  const SquareModuleRenderer();

  @override
  Path buildPath(QrModuleGeometry geometry) => Path()..addRect(geometry.rect);
}

/// Rounded rectangle with four independent corner radii, taken from
/// [QrModuleGeometry.borderRadius] (which already includes smart-corner
/// decisions).
class RoundedModuleRenderer extends QrModuleRenderer {
  /// Creates a rounded-rectangle renderer.
  const RoundedModuleRenderer();

  @override
  Path buildPath(QrModuleGeometry geometry) =>
      Path()
        ..addRRect(resolveModuleRRect(geometry.rect, geometry.borderRadius));
}

/// Circle centered in the module rectangle.
class CircleModuleRenderer extends QrModuleRenderer {
  /// Creates a circle renderer.
  const CircleModuleRenderer({this.diameterFactor = 1});

  /// Diameter as a fraction of the module side, in (0, 1].
  final double diameterFactor;

  @override
  Path buildPath(QrModuleGeometry geometry) {
    final r = geometry.rect;
    final d = r.shortestSide * diameterFactor;
    return Path()
      ..addOval(Rect.fromCenter(center: r.center, width: d, height: d));
  }
}

/// Square rotated 45 degrees, with vertices at the edge midpoints.
class DiamondModuleRenderer extends QrModuleRenderer {
  /// Creates a diamond renderer.
  const DiamondModuleRenderer();

  @override
  Path buildPath(QrModuleGeometry geometry) {
    final r = geometry.rect;
    return Path()
      ..moveTo(r.center.dx, r.top)
      ..lineTo(r.right, r.center.dy)
      ..lineTo(r.center.dx, r.bottom)
      ..lineTo(r.left, r.center.dy)
      ..close();
  }
}
