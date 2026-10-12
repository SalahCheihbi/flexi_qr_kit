import 'dart:convert';
import 'dart:typed_data';

import 'package:zxing2/qrcode.dart';

/// Reads a QR code from raw pixels.
///
/// Used by `QrValidator` to check rendered output. Implement it to validate
/// with another decoder.
abstract interface class QrDecoder {
  /// Decodes [rgba] (premultiplied RGBA bytes, row-major, [width] x
  /// [height]). Returns the text, or null when no code could be read.
  String? decode(Uint8List rgba, int width, int height);
}

/// [QrDecoder] backed by `zxing2`, a Dart port of ZXing.
///
/// It is independent of the encoder, so a successful decode is real
/// evidence that styling kept the code readable. Transparent pixels are
/// composited over white before decoding.
class ZxingQrDecoder implements QrDecoder {
  /// Creates the default decoder.
  const ZxingQrDecoder();

  @override
  String? decode(Uint8List rgba, int width, int height) {
    final pixels = Int32List(width * height);
    for (var i = 0; i < pixels.length; i++) {
      final o = i * 4;
      // Premultiplied alpha over white: c + (255 - a).
      final white = 255 - rgba[o + 3];
      final r = rgba[o] + white;
      final g = rgba[o + 1] + white;
      final b = rgba[o + 2] + white;
      pixels[i] = 0xFF000000 | (r << 16) | (g << 8) | b;
    }
    final bitmap = BinaryBitmap(
      HybridBinarizer(RGBLuminanceSource(width, height, pixels)),
    );
    final hints = DecodeHints()
      ..put(DecodeHintType.tryHarder)
      ..put(DecodeHintType.characterSet, 'UTF-8');
    final Result result;
    try {
      result = QRCodeReader().decode(bitmap, hints: hints);
    } catch (_) {
      // Not found, checksum and format failures all mean "unreadable";
      // validation must report them, never crash.
      return null;
    }
    return _fixUtf8(result);
  }

  /// zxing2 0.2.4 decodes byte segments from signed bytes, which turns any
  /// byte >= 0x80 into U+FFFD. When that happens, rebuild the text from the
  /// raw byte segments as UTF-8.
  static String _fixUtf8(Result result) {
    final text = result.text;
    if (!text.contains('\uFFFD')) return text;
    final segments = result.resultMetadata[ResultMetadataType.byteSegments];
    if (segments is! List<Int8List>) return text;
    final bytes = <int>[for (final s in segments) ...Uint8List.sublistView(s)];
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return text;
    }
  }
}
