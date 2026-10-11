/// Base class for all exceptions thrown by `flexi_qr_kit`.
sealed class FlexiQrException implements Exception {
  const FlexiQrException(this.message);

  /// Human-readable description of the failure.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the payload cannot be encoded into a QR symbol.
class QrEncodingException extends FlexiQrException {
  /// Creates an encoding exception.
  const QrEncodingException(super.message);
}

/// Thrown when the payload exceeds the capacity of a version 40 symbol at
/// the requested error correction level.
class QrDataTooLongException extends QrEncodingException {
  /// Creates a capacity exception.
  const QrDataTooLongException(super.message);
}
