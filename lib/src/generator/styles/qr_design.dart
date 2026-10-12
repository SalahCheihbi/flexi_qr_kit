import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../core/models/qr_error_correction_level.dart';
import '../../core/models/qr_finder_position.dart';
import '../../core/models/qr_module_context.dart';
import '../renderers/background/qr_background_renderer.dart';
import '../smart_corners/qr_smart_corner_engine.dart';
import 'qr_finder_style.dart';
import 'qr_logo.dart';
import 'qr_module_style.dart';

/// Returns a style for one dark module, or `null` to use
/// [QrDesign.moduleStyle].
typedef QrModuleStyleBuilder = QrModuleStyle? Function(QrModuleContext module);

/// Complete visual description of a QR code.
///
/// The design never changes the encoded matrix. It only controls how the
/// matrix is drawn.
@immutable
class QrDesign {
  /// Creates a design.
  const QrDesign({
    this.moduleStyle = const QrModuleStyle(),
    this.moduleBuilder,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.backgroundRenderer,
    this.quietZone = 4,
    this.smartCornerEngine = const QrSmartCornerEngine(),
    this.finderStyle,
    this.topLeftFinderStyle,
    this.topRightFinderStyle,
    this.bottomLeftFinderStyle,
    this.logo,
    this.styleFindersAsModules = false,
  }) : assert(quietZone >= 0, 'quietZone must be >= 0');

  /// Default style of dark modules.
  final QrModuleStyle moduleStyle;

  /// Optional per-module override, called once per dark module per paint.
  final QrModuleStyleBuilder? moduleBuilder;

  /// Fill behind the code, including the quiet zone. Use a transparent color
  /// for no background. Ignored when [backgroundRenderer] is set.
  final Color backgroundColor;

  /// Custom background, painted instead of [backgroundColor].
  final QrBackgroundRenderer? backgroundRenderer;

  /// Light margin around the symbol, in modules. The QR specification
  /// requires 4; smaller values may fail on some scanners.
  final int quietZone;

  /// Decides corner rounding for styles using smart corners. Replace it to
  /// customize the rules for the whole code.
  final QrSmartCornerEngine smartCornerEngine;

  /// Style of all three finders. When null (and no per-position style is
  /// set), finders are drawn module by module like the rest of the code.
  final QrFinderStyle? finderStyle;

  /// Whether unstyled finders are drawn module by module with the module
  /// style instead of as standard solid finders.
  ///
  /// Off by default: shapes such as dots or rounded modules break the
  /// finder's solid 1:1:3:1:1 rings and many scanners then fail to locate
  /// the code. Turn it on only to experiment, and validate the result.
  final bool styleFindersAsModules;

  /// Style of the top-left finder, replacing [finderStyle].
  final QrFinderStyle? topLeftFinderStyle;

  /// Style of the top-right finder, replacing [finderStyle].
  final QrFinderStyle? topRightFinderStyle;

  /// Style of the bottom-left finder, replacing [finderStyle].
  final QrFinderStyle? bottomLeftFinderStyle;

  /// Optional image drawn in the center of the code.
  final QrLogo? logo;

  /// Error correction used when none is requested: high when a [logo]
  /// hides part of the code, medium otherwise.
  QrErrorCorrectionLevel get defaultErrorCorrectionLevel => logo != null
      ? QrErrorCorrectionLevel.high
      : QrErrorCorrectionLevel.medium;

  /// Resolves the style for [module].
  QrModuleStyle styleFor(QrModuleContext module) =>
      moduleBuilder?.call(module) ?? moduleStyle;

  /// Resolves the style of the finder at [position], or null when it is
  /// drawn as plain modules.
  QrFinderStyle? finderStyleFor(QrFinderPosition position) =>
      switch (position) {
        QrFinderPosition.topLeft => topLeftFinderStyle,
        QrFinderPosition.topRight => topRightFinderStyle,
        QrFinderPosition.bottomLeft => bottomLeftFinderStyle,
      } ??
      finderStyle;

  /// Finder style the renderer uses at [position]: the configured
  /// [finderStyleFor], else a standard solid finder in the module color,
  /// or null when [styleFindersAsModules] draws it as plain modules.
  QrFinderStyle? effectiveFinderStyleFor(QrFinderPosition position) {
    final explicit = finderStyleFor(position);
    if (explicit != null || styleFindersAsModules) return explicit;
    final part = QrFinderPartStyle(
      color: moduleStyle.color.withValues(
        alpha: moduleStyle.color.a * moduleStyle.opacity,
      ),
      gradient: moduleStyle.gradient,
    );
    return QrFinderStyle(outer: part, inner: part);
  }

  /// Returns a copy with the given fields replaced.
  QrDesign copyWith({
    QrModuleStyle? moduleStyle,
    QrModuleStyleBuilder? moduleBuilder,
    Color? backgroundColor,
    QrBackgroundRenderer? backgroundRenderer,
    int? quietZone,
    QrSmartCornerEngine? smartCornerEngine,
    QrFinderStyle? finderStyle,
    QrFinderStyle? topLeftFinderStyle,
    QrFinderStyle? topRightFinderStyle,
    QrFinderStyle? bottomLeftFinderStyle,
    QrLogo? logo,
    bool? styleFindersAsModules,
  }) {
    return QrDesign(
      moduleStyle: moduleStyle ?? this.moduleStyle,
      moduleBuilder: moduleBuilder ?? this.moduleBuilder,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundRenderer: backgroundRenderer ?? this.backgroundRenderer,
      quietZone: quietZone ?? this.quietZone,
      smartCornerEngine: smartCornerEngine ?? this.smartCornerEngine,
      finderStyle: finderStyle ?? this.finderStyle,
      topLeftFinderStyle: topLeftFinderStyle ?? this.topLeftFinderStyle,
      topRightFinderStyle: topRightFinderStyle ?? this.topRightFinderStyle,
      bottomLeftFinderStyle:
          bottomLeftFinderStyle ?? this.bottomLeftFinderStyle,
      logo: logo ?? this.logo,
      styleFindersAsModules:
          styleFindersAsModules ?? this.styleFindersAsModules,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QrDesign &&
      other.moduleStyle == moduleStyle &&
      other.moduleBuilder == moduleBuilder &&
      other.backgroundColor == backgroundColor &&
      other.backgroundRenderer == backgroundRenderer &&
      other.quietZone == quietZone &&
      other.smartCornerEngine == smartCornerEngine &&
      other.finderStyle == finderStyle &&
      other.topLeftFinderStyle == topLeftFinderStyle &&
      other.topRightFinderStyle == topRightFinderStyle &&
      other.bottomLeftFinderStyle == bottomLeftFinderStyle &&
      other.logo == logo &&
      other.styleFindersAsModules == styleFindersAsModules;

  @override
  int get hashCode => Object.hash(
    moduleStyle,
    moduleBuilder,
    backgroundColor,
    backgroundRenderer,
    quietZone,
    smartCornerEngine,
    finderStyle,
    topLeftFinderStyle,
    topRightFinderStyle,
    bottomLeftFinderStyle,
    logo,
    styleFindersAsModules,
  );
}
