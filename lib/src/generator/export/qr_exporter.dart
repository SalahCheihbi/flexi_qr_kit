import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../../core/exceptions/flexi_qr_exception.dart';
import '../../core/models/qr_error_correction_level.dart';
import '../../core/models/qr_validation_result.dart';
import '../encoder/qr_encoder.dart';
import '../encoder/qr_package_encoder.dart';
import '../matrix/qr_matrix.dart';
import '../styles/qr_design.dart';
import '../validation/qr_validator.dart';
import 'qr_image_renderer.dart';

/// A PNG produced by [QrExporter.exportPng].
@immutable
class QrExportResult {
  /// Creates an export result.
  const QrExportResult({
    required this.bytes,
    required this.width,
    required this.height,
    required this.matrix,
    required this.validation,
  });

  /// Encoded PNG bytes.
  final Uint8List bytes;

  /// Width in physical pixels.
  final int width;

  /// Height in physical pixels.
  final int height;

  /// The encoded matrix that was drawn.
  final QrMatrix matrix;

  /// Validation of the exact pixels in [bytes].
  final QrValidationResult validation;
}

/// Exports styled QR codes as images.
///
/// Export uses the same rendering pipeline as `FlexiQrGenerator`, so the
/// image matches the on-screen preview. Every export is validated by
/// decoding its own pixels.
class QrExporter {
  /// Creates an exporter.
  const QrExporter({
    this.encoder = const QrPackageEncoder(),
    this.validator = const QrValidator(),
  });

  /// Encoder used for [exportPng].
  final QrEncoder encoder;

  /// Validator used for [exportPng].
  final QrValidator validator;

  /// Renders [matrix] at [size] logical pixels times [pixelRatio].
  Future<ui.Image> renderImage({
    required QrMatrix matrix,
    required QrDesign design,
    required double size,
    double pixelRatio = 1,
    ui.Image? logoImage,
  }) => renderQrImage(
    matrix: matrix,
    design: design,
    size: size,
    pixelRatio: pixelRatio,
    logoImage: logoImage,
  );

  /// Encodes [data], renders it and returns a validated PNG.
  ///
  /// The image is `size * pixelRatio` pixels wide. Use [pixelRatio] for
  /// print-quality output: radii and spacing scale like on a high-DPI
  /// screen.
  ///
  /// When [design] has a logo and [logoImage] is null, the logo is loaded
  /// from `QrLogo.image` (requires the Flutter bindings).
  ///
  /// [transparentBackground] replaces `QrDesign.backgroundColor` with full
  /// transparency (a `backgroundRenderer`, if any, still paints).
  ///
  /// In [QrValidationMode.strict] (the default), a code that fails
  /// validation throws [QrValidationException] instead of being exported.
  /// [QrValidationMode.advanced] always exports and reports the issues.
  Future<QrExportResult> exportPng(
    String data, {
    QrDesign design = const QrDesign(),
    QrErrorCorrectionLevel? errorCorrectionLevel,
    int? version,
    double size = 512,
    double pixelRatio = 1,
    ui.Image? logoImage,
    bool transparentBackground = false,
    QrValidationMode validationMode = QrValidationMode.strict,
  }) async {
    final effective = transparentBackground
        ? design.copyWith(backgroundColor: const ui.Color(0x00000000))
        : design;
    final matrix = encoder.encode(
      data,
      errorCorrectionLevel:
          errorCorrectionLevel ?? effective.defaultErrorCorrectionLevel,
      version: version,
    );
    final logo = effective.logo;
    final ownsLogo = logoImage == null && logo != null;
    final logoPixels = ownsLogo
        ? await resolveQrLogoImage(logo.image)
        : logoImage;

    final image = await renderImage(
      matrix: matrix,
      design: effective,
      size: size,
      pixelRatio: pixelRatio,
      logoImage: logoPixels,
    );
    try {
      final check = validator.checkDecoding(
        expected: data,
        rgba: await imageToRgba(image),
        width: image.width,
        height: image.height,
      );
      final validation = QrValidationResult(
        issues: [
          ...validator.checkConfiguration(
            matrix: matrix,
            design: effective,
            size: size,
            pixelRatio: pixelRatio,
          ),
          ?check.issue,
        ],
        decodedText: check.decodedText,
      );
      if (validationMode == QrValidationMode.strict && !validation.isUsable) {
        throw QrValidationException(validation);
      }
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      return QrExportResult(
        bytes: png!.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
        width: image.width,
        height: image.height,
        matrix: matrix,
        validation: validation,
      );
    } finally {
      image.dispose();
      if (ownsLogo) logoPixels?.dispose();
    }
  }
}
