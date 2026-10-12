import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/material.dart';

/// Finder looks offered by the designer.
enum FinderPreset { standard, square, rounded, circle }

/// State of the designer page, turned into a [QrDesign] by [toDesign].
@immutable
class DesignerConfig {
  const DesignerConfig({
    this.data = 'https://pub.dev/packages/flexi_qr_kit',
    this.shape = QrModuleShape.custom,
    this.cornerMode = QrCornerMode.manual,
    this.topLeft = 4,
    this.topRight = 4,
    this.bottomRight = 4,
    this.bottomLeft = 0,
    this.scale = 1,
    this.spacing = 0,
    this.color = const Color(0xFF111827),
    this.gradient = false,
    this.finder = FinderPreset.rounded,
    this.logo = false,
    this.quietZone = 4,
    this.errorCorrectionLevel,
  });

  final String data;
  final QrModuleShape shape;
  final QrCornerMode cornerMode;
  final double topLeft;
  final double topRight;
  final double bottomRight;
  final double bottomLeft;
  final double scale;
  final double spacing;
  final Color color;
  final bool gradient;
  final FinderPreset finder;
  final bool logo;
  final int quietZone;

  /// Null picks H with a logo and M otherwise.
  final QrErrorCorrectionLevel? errorCorrectionLevel;

  static const logoImage = AssetImage('assets/logo.png');

  /// Colors offered by the designer.
  static const palette = [
    Color(0xFF111827),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFC62828),
    Color(0xFFBDBDBD),
  ];

  BorderRadius get borderRadius => BorderRadius.only(
    topLeft: Radius.circular(topLeft),
    topRight: Radius.circular(topRight),
    bottomRight: Radius.circular(bottomRight),
    bottomLeft: Radius.circular(bottomLeft),
  );

  QrDesign toDesign() {
    return QrDesign(
      quietZone: quietZone,
      moduleStyle: QrModuleStyle(
        shape: shape,
        cornerMode: cornerMode,
        borderRadius: borderRadius,
        scale: scale,
        spacing: spacing,
        color: color,
        gradient: gradient
            ? LinearGradient(colors: [color, const Color(0xFF0277BD)])
            : null,
      ),
      finderStyle: switch (finder) {
        FinderPreset.standard => null,
        FinderPreset.square => QrFinderStyle.square(color: color),
        FinderPreset.rounded => QrFinderStyle.rounded(color: color),
        FinderPreset.circle => QrFinderStyle.circle(color: color),
      },
      logo: logo
          ? const QrLogo(
              image: logoImage,
              backgroundColor: Color(0xFFFFFFFF),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            )
          : null,
    );
  }

  DesignerConfig copyWith({
    String? data,
    QrModuleShape? shape,
    QrCornerMode? cornerMode,
    double? topLeft,
    double? topRight,
    double? bottomRight,
    double? bottomLeft,
    double? scale,
    double? spacing,
    Color? color,
    bool? gradient,
    FinderPreset? finder,
    bool? logo,
    int? quietZone,
    QrErrorCorrectionLevel? errorCorrectionLevel,
    bool autoErrorCorrection = false,
  }) {
    return DesignerConfig(
      data: data ?? this.data,
      shape: shape ?? this.shape,
      cornerMode: cornerMode ?? this.cornerMode,
      topLeft: topLeft ?? this.topLeft,
      topRight: topRight ?? this.topRight,
      bottomRight: bottomRight ?? this.bottomRight,
      bottomLeft: bottomLeft ?? this.bottomLeft,
      scale: scale ?? this.scale,
      spacing: spacing ?? this.spacing,
      color: color ?? this.color,
      gradient: gradient ?? this.gradient,
      finder: finder ?? this.finder,
      logo: logo ?? this.logo,
      quietZone: quietZone ?? this.quietZone,
      errorCorrectionLevel: autoErrorCorrection
          ? null
          : errorCorrectionLevel ?? this.errorCorrectionLevel,
    );
  }
}
