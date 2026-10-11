/// QR error correction level (ISO/IEC 18004).
///
/// Higher levels recover more damaged or covered modules (e.g. by a logo)
/// at the cost of a denser matrix.
enum QrErrorCorrectionLevel {
  /// Recovers roughly 7% of codewords.
  low(0.07),

  /// Recovers roughly 15% of codewords.
  medium(0.15),

  /// Recovers roughly 25% of codewords.
  quartile(0.25),

  /// Recovers roughly 30% of codewords.
  high(0.30);

  const QrErrorCorrectionLevel(this.recoveryCapacity);

  /// Approximate fraction of codewords that can be restored.
  ///
  /// This is a theoretical upper bound: it is not a guarantee that a styled
  /// or partially covered code will scan.
  final double recoveryCapacity;
}
