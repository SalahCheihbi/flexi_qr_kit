/// Functional role of a module inside the QR symbol.
enum QrModuleType {
  /// One of the three 7x7 position detection patterns.
  finder,

  /// The light 1-module border separating a finder from the data area.
  separator,

  /// The alternating dark/light lines on row 6 and column 6.
  timing,

  /// A 5x5 alignment pattern (versions 2 and up).
  alignment,

  /// Error correction level and mask pattern bits.
  formatInfo,

  /// Version bits (versions 7 and up).
  versionInfo,

  /// The single always-dark module next to the bottom-left finder.
  darkModule,

  /// Encoded data and error correction codewords.
  data;

  /// Whether the module belongs to a structure scanners rely on to locate
  /// and decode the symbol. Styling these aggressively hurts readability.
  bool get isProtected => this != QrModuleType.data;
}
