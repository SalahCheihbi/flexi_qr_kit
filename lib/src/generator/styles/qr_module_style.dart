import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../renderers/modules/qr_module_renderer.dart';
import 'qr_module_shape.dart';

/// Visual configuration of dark modules.
///
/// Lengths ([borderRadius], [spacing]) are logical pixels. Radii larger than
/// half the drawn module are clamped, so `Radius.circular(999)` always
/// yields the roundest possible corner.
@immutable
class QrModuleStyle {
  /// Creates a module style.
  const QrModuleStyle({
    this.shape = QrModuleShape.square,
    this.color = const Color(0xFF000000),
    this.opacity = 1,
    this.gradient,
    this.borderRadius,
    this.scale = 1,
    this.spacing = 0,
    this.rotation = 0,
    this.renderer,
  }) : assert(opacity >= 0 && opacity <= 1, 'opacity must be in [0, 1]'),
       assert(scale > 0 && scale <= 1, 'scale must be in (0, 1]'),
       assert(spacing >= 0, 'spacing must be >= 0');

  /// Built-in outline. Ignored when [renderer] is set.
  final QrModuleShape shape;

  /// Fill color. Ignored when [gradient] is set.
  final Color color;

  /// Extra opacity multiplier in [0, 1], applied on top of [color] or
  /// [gradient].
  final double opacity;

  /// Gradient spread across the whole QR area (not per module).
  final Gradient? gradient;

  /// Independent corner radii for [QrModuleShape.custom] and
  /// [QrModuleShape.rounded].
  final BorderRadius? borderRadius;

  /// Fraction of the cell the module occupies, centered, in (0, 1].
  final double scale;

  /// Gap in logical pixels removed from each module before [scale] applies.
  /// Spacing larger than the cell is clamped so modules never disappear.
  final double spacing;

  /// Rotation of each module around its center, in radians.
  ///
  /// Rotation keeps the module center fixed, so the code stays decodable, but
  /// large angles on large modules reduce contrast at cell edges.
  final double rotation;

  /// Custom renderer that replaces [shape].
  final QrModuleRenderer? renderer;

  /// Returns a copy with the given fields replaced.
  QrModuleStyle copyWith({
    QrModuleShape? shape,
    Color? color,
    double? opacity,
    Gradient? gradient,
    BorderRadius? borderRadius,
    double? scale,
    double? spacing,
    double? rotation,
    QrModuleRenderer? renderer,
  }) {
    return QrModuleStyle(
      shape: shape ?? this.shape,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      gradient: gradient ?? this.gradient,
      borderRadius: borderRadius ?? this.borderRadius,
      scale: scale ?? this.scale,
      spacing: spacing ?? this.spacing,
      rotation: rotation ?? this.rotation,
      renderer: renderer ?? this.renderer,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QrModuleStyle &&
      other.shape == shape &&
      other.color == color &&
      other.opacity == opacity &&
      other.gradient == gradient &&
      other.borderRadius == borderRadius &&
      other.scale == scale &&
      other.spacing == spacing &&
      other.rotation == rotation &&
      other.renderer == renderer;

  @override
  int get hashCode => Object.hash(
    shape,
    color,
    opacity,
    gradient,
    borderRadius,
    scale,
    spacing,
    rotation,
    renderer,
  );

  @override
  String toString() => 'QrModuleStyle(shape: $shape, color: $color)';
}
