import 'dart:typed_data';

import '../../core/models/qr_error_correction_level.dart';
import '../matrix/qr_matrix.dart';

/// Turns a payload into a [QrMatrix].
///
/// Implement this to plug in another encoding library. Implementations must
/// throw `QrDataTooLongException` when the payload does not fit.
abstract interface class QrEncoder {
  /// Encodes [data] as UTF-8 bytes.
  ///
  /// When [version] is null the smallest version that fits is chosen.
  QrMatrix encode(
    String data, {
    QrErrorCorrectionLevel errorCorrectionLevel,
    int? version,
  });

  /// Encodes a raw byte payload.
  QrMatrix encodeBytes(
    Uint8List bytes, {
    QrErrorCorrectionLevel errorCorrectionLevel,
    int? version,
  });
}
