import 'package:flutter/painting.dart';

import '../modules/module_geometry.dart';
import '../qr_render_layout.dart';

/// Contract for drawing the area behind the modules.
///
/// When set on `QrDesign.backgroundRenderer`, it replaces
/// `QrDesign.backgroundColor`. It is painted first, so anything it draws
/// sits under the modules. Keep it light enough for scanners to see the
/// dark modules.
abstract class QrBackgroundRenderer {
  /// Const constructor for subclasses.
  const QrBackgroundRenderer();

  /// Paints the background for [layout].
  void paint(Canvas canvas, QrRenderLayout layout);
}

/// Solid or gradient fill with independent corner radii.
class FilledBackgroundRenderer extends QrBackgroundRenderer {
  /// Creates a filled background.
  const FilledBackgroundRenderer({
    this.color = const Color(0xFFFFFFFF),
    this.gradient,
    this.borderRadius = BorderRadius.zero,
    this.coverQuietZone = true,
  });

  /// Fill color. Ignored when [gradient] is set.
  final Color color;

  /// Gradient spread across the filled area.
  final Gradient? gradient;

  /// Corner radii in logical pixels, clamped to half the side.
  final BorderRadius borderRadius;

  /// Whether the fill includes the quiet zone or only the modules.
  final bool coverQuietZone;

  @override
  void paint(Canvas canvas, QrRenderLayout layout) {
    final rect = coverQuietZone ? layout.bounds : layout.matrixRect;
    final paint = Paint()..color = color;
    final gradient = this.gradient;
    if (gradient != null) paint.shader = gradient.createShader(rect);
    canvas.drawRRect(resolveModuleRRect(rect, borderRadius), paint);
  }

  @override
  bool operator ==(Object other) =>
      other is FilledBackgroundRenderer &&
      other.color == color &&
      other.gradient == gradient &&
      other.borderRadius == borderRadius &&
      other.coverQuietZone == coverQuietZone;

  @override
  int get hashCode =>
      Object.hash(color, gradient, borderRadius, coverQuietZone);
}
