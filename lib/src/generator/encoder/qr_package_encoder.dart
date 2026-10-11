import 'dart:convert';
import 'dart:typed_data';

import 'package:qr/qr.dart' as qr;

import '../../core/exceptions/flexi_qr_exception.dart';
import '../../core/models/qr_error_correction_level.dart';
import '../matrix/qr_matrix.dart';
import 'qr_encoder.dart';

/// [QrEncoder] backed by the standards-compliant `qr` package.
///
/// Text is encoded in byte mode as UTF-8, which supports any Unicode
/// payload, including Arabic and emoji.
class QrPackageEncoder implements QrEncoder {
  /// Creates the default encoder.
  const QrPackageEncoder();

  @override
  QrMatrix encode(
    String data, {
    QrErrorCorrectionLevel errorCorrectionLevel = QrErrorCorrectionLevel.medium,
    int? version,
  }) => encodeBytes(
    Uint8List.fromList(utf8.encode(data)),
    errorCorrectionLevel: errorCorrectionLevel,
    version: version,
  );

  @override
  QrMatrix encodeBytes(
    Uint8List bytes, {
    QrErrorCorrectionLevel errorCorrectionLevel = QrErrorCorrectionLevel.medium,
    int? version,
  }) {
    if (version != null && (version < 1 || version > 40)) {
      throw ArgumentError.value(version, 'version', 'Must be in 1..40');
    }
    final level = _levels[errorCorrectionLevel]!;
    final qr.QrCode code;
    final qr.QrImage image;
    try {
      code = version == null
          ? qr.QrCode.fromUint8List(data: bytes, errorCorrectLevel: level)
          : (qr.QrCode(version, level)
              ..addByteData(ByteData.sublistView(bytes)));
      // Building the image fails when data overflows a fixed version.
      image = qr.QrImage(code);
    } on qr.InputTooLongException catch (e) {
      throw QrDataTooLongException(e.message);
    }

    final n = image.moduleCount;
    return QrMatrix.fromModules(
      List.generate(n, (r) => List.generate(n, (c) => image.isDark(r, c))),
      errorCorrectionLevel: errorCorrectionLevel,
    );
  }

  static const _levels = {
    QrErrorCorrectionLevel.low: qr.QrErrorCorrectLevel.L,
    QrErrorCorrectionLevel.medium: qr.QrErrorCorrectLevel.M,
    QrErrorCorrectionLevel.quartile: qr.QrErrorCorrectLevel.Q,
    QrErrorCorrectionLevel.high: qr.QrErrorCorrectLevel.H,
  };
}
