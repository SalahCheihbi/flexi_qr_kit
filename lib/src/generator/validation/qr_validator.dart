import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../core/models/qr_error_correction_level.dart';
import '../../core/models/qr_finder_position.dart';
import '../../core/models/qr_module_type.dart';
import '../../core/models/qr_validation_result.dart';
import '../encoder/qr_encoder.dart';
import '../encoder/qr_package_encoder.dart';
import '../export/qr_image_renderer.dart';
import '../matrix/qr_matrix.dart';
import '../renderers/background/qr_background_renderer.dart';
import '../renderers/logo/qr_logo_layout.dart';
import '../renderers/qr_render_layout.dart';
import '../styles/qr_design.dart';
import '../styles/qr_finder_style.dart';
import '../styles/qr_module_shape.dart';
import 'qr_decoder.dart';

/// WCAG contrast ratio between two opaque colors, from 1 (none) to 21.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Outcome of [QrValidator.checkDecoding].
class QrDecodeCheck {
  /// Creates a decode check outcome.
  const QrDecodeCheck({this.issue, this.decodedText});

  /// The failure, or null when the image decoded to the expected content.
  final QrValidationIssue? issue;

  /// Decoded text, or null when nothing could be read.
  final String? decodedText;
}

/// Checks that a styled QR code stays readable.
///
/// Two kinds of checks:
/// * [checkConfiguration] inspects the design (quiet zone, contrast, logo
///   coverage, module pixel size, risky settings) without rendering.
/// * [checkDecoding] decodes the actual rendered pixels with an independent
///   [QrDecoder] and compares the result with the input.
///
/// [validate] runs both. A valid result is strong evidence, not a
/// guarantee: also test on real Android and iOS devices.
class QrValidator {
  /// Creates a validator.
  const QrValidator({
    this.decoder = const ZxingQrDecoder(),
    this.encoder = const QrPackageEncoder(),
  });

  /// Contrast below this ratio is an error.
  static const double minContrast = 3;

  /// Contrast below this ratio is a warning.
  static const double recommendedContrast = 4.5;

  /// Modules smaller than this many physical pixels are an error.
  static const double minModulePixels = 2;

  /// Modules smaller than this many physical pixels are a warning.
  static const double recommendedModulePixels = 4;

  /// Decoder used by [checkDecoding].
  final QrDecoder decoder;

  /// Encoder used by [validate].
  final QrEncoder encoder;

  /// Encodes [data], renders it with [design] at [size] logical pixels
  /// times [pixelRatio], and runs every check.
  ///
  /// [logoImage] is optional: without it the logo container is still drawn,
  /// so coverage is the same. Set [decode] to false for a fast,
  /// configuration-only result (e.g. while the user drags a slider).
  Future<QrValidationResult> validate(
    String data, {
    QrDesign design = const QrDesign(),
    QrErrorCorrectionLevel? errorCorrectionLevel,
    int? version,
    double size = 512,
    double pixelRatio = 1,
    ui.Image? logoImage,
    bool decode = true,
  }) async {
    final matrix = encoder.encode(
      data,
      errorCorrectionLevel:
          errorCorrectionLevel ?? design.defaultErrorCorrectionLevel,
      version: version,
    );
    final issues = checkConfiguration(
      matrix: matrix,
      design: design,
      size: size,
      pixelRatio: pixelRatio,
    );
    if (!decode) return QrValidationResult(issues: issues);

    final image = await renderQrImage(
      matrix: matrix,
      design: design,
      size: size,
      pixelRatio: pixelRatio,
      logoImage: logoImage,
    );
    try {
      final check = checkDecoding(
        expected: data,
        rgba: await imageToRgba(image),
        width: image.width,
        height: image.height,
      );
      return QrValidationResult(
        issues: [...issues, ?check.issue],
        decodedText: check.decodedText,
      );
    } finally {
      image.dispose();
    }
  }

  /// Decodes rendered pixels and compares them with [expected].
  QrDecodeCheck checkDecoding({
    required String expected,
    required Uint8List rgba,
    required int width,
    required int height,
  }) {
    final text = decoder.decode(rgba, width, height);
    if (text == null) {
      return const QrDecodeCheck(
        issue: QrValidationIssue(
          QrIssueCode.decodeFailed,
          QrIssueSeverity.error,
          'The rendered code could not be decoded.',
        ),
      );
    }
    if (text != expected) {
      return QrDecodeCheck(
        decodedText: text,
        issue: const QrValidationIssue(
          QrIssueCode.contentMismatch,
          QrIssueSeverity.error,
          'The rendered code decodes to different content than the input.',
        ),
      );
    }
    return QrDecodeCheck(decodedText: text);
  }

  /// Inspects [design] applied to [matrix] at [size] x [pixelRatio]
  /// without rendering.
  List<QrValidationIssue> checkConfiguration({
    required QrMatrix matrix,
    required QrDesign design,
    required double size,
    double pixelRatio = 1,
  }) {
    final issues = <QrValidationIssue>[];
    void warn(QrIssueCode code, String message) =>
        issues.add(QrValidationIssue(code, QrIssueSeverity.warning, message));
    void fail(QrIssueCode code, String message) =>
        issues.add(QrValidationIssue(code, QrIssueSeverity.error, message));

    // Quiet zone.
    if (design.quietZone < 4) {
      warn(
        QrIssueCode.quietZoneTooSmall,
        'Quiet zone is ${design.quietZone} modules; the specification '
        'requires 4.',
      );
    }

    // Module pixel size.
    final modules = matrix.size + 2 * design.quietZone;
    final modulePx = size * pixelRatio / modules;
    final pxText = modulePx.toStringAsFixed(1);
    if (modulePx < minModulePixels) {
      fail(
        QrIssueCode.moduleTooSmall,
        'Modules are $pxText px; at least $minModulePixels px are needed.',
      );
    } else if (modulePx < recommendedModulePixels) {
      warn(
        QrIssueCode.moduleTooSmall,
        'Modules are $pxText px; $recommendedModulePixels px or more '
        'scan more reliably.',
      );
    }

    // Colors.
    final background = _backgroundColors(design);
    if (design.backgroundRenderer == null && design.backgroundColor.a < 1) {
      warn(
        QrIssueCode.transparentBackground,
        'The background is transparent; contrast depends on what is '
        'behind the code.',
      );
    }
    if (background != null) _checkColors(design, background, warn, fail);

    // Logo coverage.
    final logo = design.logo;
    if (logo != null) {
      final layout = QrLogoLayout.compute(
        QrRenderLayout.compute(Size.square(size), matrix.size, 0),
        matrix.size,
        logo,
      );
      if (layout != null) {
        var data = 0, covered = 0;
        for (var r = 0; r < matrix.size; r++) {
          for (var c = 0; c < matrix.size; c++) {
            if (matrix.typeAt(r, c) != QrModuleType.data) continue;
            data++;
            if (layout.coversModule(r, c)) covered++;
          }
        }
        final ratio = covered / data;
        final capacity = matrix.errorCorrectionLevel.recoveryCapacity;
        final pct = (ratio * 100).toStringAsFixed(0);
        final capPct = (capacity * 100).toStringAsFixed(0);
        final level = matrix.errorCorrectionLevel.name;
        if (ratio > capacity) {
          fail(
            QrIssueCode.logoTooLarge,
            'The logo hides $pct% of the data, more than the $capPct% '
            'that error correction level $level can recover.',
          );
        } else if (ratio > capacity / 2) {
          warn(
            QrIssueCode.logoTooLarge,
            'The logo hides $pct% of the data, over half of what error '
            'correction level $level can recover ($capPct%).',
          );
        }
      }
    }

    // Finder geometry.
    final unsafe = QrFinderPosition.values
        .map(design.finderStyleFor)
        .whereType<QrFinderStyle>()
        .any(
          (s) =>
              s.effectiveOuterThickness < QrFinderStyle.safeMinThickness ||
              s.effectiveOuterThickness > QrFinderStyle.safeMaxThickness,
        );
    final shape = design.moduleStyle.shape;
    final modularFinders =
        design.styleFindersAsModules &&
        QrFinderPosition.values.any((p) => design.finderStyleFor(p) == null) &&
        (design.moduleStyle.renderer != null ||
            design.moduleStyle.scale < 1 ||
            design.moduleStyle.spacing > 0 ||
            !{
              QrModuleShape.square,
              QrModuleShape.connected,
              QrModuleShape.smooth,
            }.contains(shape));
    if (unsafe) {
      warn(
        QrIssueCode.unsafeFinderGeometry,
        'A finder frame thickness is outside the scanner-safe range '
        '(${QrFinderStyle.safeMinThickness}-'
        '${QrFinderStyle.safeMaxThickness} modules).',
      );
    }
    if (modularFinders) {
      warn(
        QrIssueCode.unsafeFinderGeometry,
        'Finders are drawn with a module shape that leaves gaps in their '
        'solid rings; many scanners then fail to locate the code.',
      );
    }

    // Risky module settings.
    final style = design.moduleStyle;
    if (style.scale < 0.6) {
      warn(
        QrIssueCode.smallModuleScale,
        'Modules fill only ${(style.scale * 100).round()}% of their cell.',
      );
    }
    final roundShape =
        style.renderer == null &&
        (style.shape == QrModuleShape.circle ||
            style.shape == QrModuleShape.dots);
    final quarterTurns = style.rotation / (math.pi / 2);
    final isQuarterTurn = (quarterTurns - quarterTurns.round()).abs() < 1e-9;
    if (!roundShape && !isQuarterTurn) {
      warn(
        QrIssueCode.rotatedModules,
        'Rotated modules cover less of their cell, which lowers '
        'readability.',
      );
    }

    return issues;
  }

  /// Opaque background colors (composited over white), or null when a
  /// custom background renderer makes them unknown.
  static List<Color>? _backgroundColors(QrDesign design) {
    final renderer = design.backgroundRenderer;
    final List<Color> colors;
    if (renderer == null) {
      colors = [design.backgroundColor];
    } else if (renderer is FilledBackgroundRenderer) {
      colors = renderer.gradient?.colors ?? [renderer.color];
    } else {
      return null;
    }
    const white = Color(0xFFFFFFFF);
    return [for (final c in colors) Color.alphaBlend(c, white)];
  }

  static void _checkColors(
    QrDesign design,
    List<Color> background,
    void Function(QrIssueCode, String) warn,
    void Function(QrIssueCode, String) fail,
  ) {
    final style = design.moduleStyle;
    final dark = <Color>[
      for (final c in style.gradient?.colors ?? [style.color])
        c.withValues(alpha: c.a * style.opacity),
      for (final position in QrFinderPosition.values)
        if (design.finderStyleFor(position) case final finder?)
          for (final part in [finder.outer, finder.inner])
            ...part.gradient?.colors ?? [part.color],
    ];

    var minRatio = double.infinity;
    var inverted = false;
    for (final bg in background) {
      for (final d in dark) {
        final fg = Color.alphaBlend(d, bg);
        minRatio = math.min(minRatio, contrastRatio(fg, bg));
        if (fg.computeLuminance() > bg.computeLuminance()) inverted = true;
      }
    }

    final ratio = '${minRatio.toStringAsFixed(1)}:1';
    if (minRatio < minContrast) {
      fail(
        QrIssueCode.lowContrast,
        'Contrast between modules and background is $ratio; at least '
        '$minContrast:1 is needed.',
      );
    } else if (minRatio < recommendedContrast) {
      warn(
        QrIssueCode.lowContrast,
        'Contrast between modules and background is $ratio; '
        '$recommendedContrast:1 or more is recommended.',
      );
    }
    if (inverted) {
      warn(
        QrIssueCode.invertedColors,
        'Modules are lighter than the background; many scanners cannot '
        'read inverted codes.',
      );
    }
  }
}
