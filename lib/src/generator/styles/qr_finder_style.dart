import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../renderers/finders/qr_finder_renderer.dart';

/// Fill and corner radii of one part of a finder pattern.
///
/// [borderRadius] is in logical pixels and clamped to half the part's side,
/// so `Radius.circular(999)` always yields the roundest corner.
@immutable
class QrFinderPartStyle {
  /// Creates a finder part style.
  const QrFinderPartStyle({
    this.color = const Color(0xFF000000),
    this.gradient,
    this.borderRadius = BorderRadius.zero,
  });

  /// Fill color. Ignored when [gradient] is set.
  final Color color;

  /// Gradient spread across the whole QR area, like module gradients.
  final Gradient? gradient;

  /// Independent corner radii of the part's outline.
  final BorderRadius borderRadius;

  /// Returns a copy with the given fields replaced.
  QrFinderPartStyle copyWith({
    Color? color,
    Gradient? gradient,
    BorderRadius? borderRadius,
  }) {
    return QrFinderPartStyle(
      color: color ?? this.color,
      gradient: gradient ?? this.gradient,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QrFinderPartStyle &&
      other.color == color &&
      other.gradient == gradient &&
      other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(color, gradient, borderRadius);
}

/// Visual configuration of a finder pattern, drawn as whole shapes instead
/// of individual modules.
///
/// A finder has three parts:
/// - [outer]: the 7x7 frame, one module thick. Its hole follows the outer
///   corners concentrically.
/// - [inner]: the 3x3 eye in the center.
/// - [separator]: the one-module light band around the finder. Not drawn
///   when null, so the background shows through. Keep it light: scanners
///   need contrast around the finder.
///
/// Scanners locate finders by their 1:1:3:1:1 dark/light proportions. In
/// [safeMode] (the default) the frame thickness is kept close to one module
/// so those proportions stay within scanner tolerance; turn it off to
/// experiment, and validate the result.
@immutable
class QrFinderStyle {
  /// Creates a finder style.
  const QrFinderStyle({
    this.outer = const QrFinderPartStyle(),
    this.inner = const QrFinderPartStyle(),
    this.separator,
    this.renderer = const DefaultQrFinderRenderer(),
    this.outerThickness = 1,
    this.safeMode = true,
  }) : assert(
         outerThickness > 0 && outerThickness < 2,
         'outerThickness must be in (0, 2) modules',
       );

  /// Square frame and eye with sharp corners.
  factory QrFinderStyle.square({
    Color color = const Color(0xFF000000),
    Color? innerColor,
    double outerThickness = 1,
    bool safeMode = true,
  }) => QrFinderStyle(
    outer: QrFinderPartStyle(color: color),
    inner: QrFinderPartStyle(color: innerColor ?? color),
    outerThickness: outerThickness,
    safeMode: safeMode,
  );

  /// Frame and eye with uniformly rounded corners, in logical pixels.
  ///
  /// For different radii per corner, use the default constructor with
  /// `BorderRadius.only`.
  factory QrFinderStyle.rounded({
    Radius outerRadius = const Radius.circular(12),
    Radius innerRadius = const Radius.circular(6),
    Color color = const Color(0xFF000000),
    Color? innerColor,
    double outerThickness = 1,
    bool safeMode = true,
  }) => QrFinderStyle(
    outer: QrFinderPartStyle(
      color: color,
      borderRadius: BorderRadius.all(outerRadius),
    ),
    inner: QrFinderPartStyle(
      color: innerColor ?? color,
      borderRadius: BorderRadius.all(innerRadius),
    ),
    outerThickness: outerThickness,
    safeMode: safeMode,
  );

  /// Circle-inspired finder: a round ring around a round eye. The 7x7 and
  /// 3x3 proportions are unchanged, so scanners still recognize it.
  factory QrFinderStyle.circle({
    Color color = const Color(0xFF000000),
    Color? innerColor,
    double outerThickness = 1,
    bool safeMode = true,
  }) => QrFinderStyle(
    outer: QrFinderPartStyle(
      color: color,
      borderRadius: const BorderRadius.all(Radius.circular(999)),
    ),
    inner: QrFinderPartStyle(
      color: innerColor ?? color,
      borderRadius: const BorderRadius.all(Radius.circular(999)),
    ),
    outerThickness: outerThickness,
    safeMode: safeMode,
  );

  /// Smallest frame thickness applied in [safeMode], in modules.
  static const double safeMinThickness = 0.8;

  /// Largest frame thickness applied in [safeMode], in modules.
  static const double safeMaxThickness = 1.2;

  /// Style of the 7x7 frame.
  final QrFinderPartStyle outer;

  /// Style of the 3x3 eye.
  final QrFinderPartStyle inner;

  /// Style of the light band around the finder, or null to leave it empty.
  final QrFinderPartStyle? separator;

  /// Builds the outlines of the three parts.
  final QrFinderRenderer renderer;

  /// Thickness of the outer frame in modules, in (0, 2). The standard is 1.
  /// The 3x3 eye never moves; a thicker frame narrows the gap around it.
  final double outerThickness;

  /// Whether finder geometry is kept scanner-safe. When true,
  /// [outerThickness] is clamped to [safeMinThickness]..[safeMaxThickness].
  final bool safeMode;

  /// Frame thickness actually drawn, in modules.
  double get effectiveOuterThickness => safeMode
      ? outerThickness.clamp(safeMinThickness, safeMaxThickness).toDouble()
      : outerThickness;

  /// Returns a copy with the given fields replaced.
  QrFinderStyle copyWith({
    QrFinderPartStyle? outer,
    QrFinderPartStyle? inner,
    QrFinderPartStyle? separator,
    QrFinderRenderer? renderer,
    double? outerThickness,
    bool? safeMode,
  }) {
    return QrFinderStyle(
      outer: outer ?? this.outer,
      inner: inner ?? this.inner,
      separator: separator ?? this.separator,
      renderer: renderer ?? this.renderer,
      outerThickness: outerThickness ?? this.outerThickness,
      safeMode: safeMode ?? this.safeMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QrFinderStyle &&
      other.outer == outer &&
      other.inner == inner &&
      other.separator == separator &&
      other.renderer == renderer &&
      other.outerThickness == outerThickness &&
      other.safeMode == safeMode;

  @override
  int get hashCode =>
      Object.hash(outer, inner, separator, renderer, outerThickness, safeMode);
}
