import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A QR code read by the scanner.
@immutable
class QrScanResult {
  /// Creates a scan result.
  const QrScanResult({
    required this.value,
    this.rawBytes,
    this.corners = const [],
    this.size = Size.zero,
  });

  /// Converts a `mobile_scanner` [Barcode].
  factory QrScanResult.fromBarcode(Barcode barcode) {
    return QrScanResult(
      value: barcode.rawValue ?? '',
      rawBytes: switch (barcode.rawDecodedBytes) {
        DecodedBarcodeBytes(:final bytes) => bytes,
        DecodedVisionBarcodeBytes(:final bytes, :final rawBytes) =>
          bytes ?? rawBytes,
        null => null,
      },
      corners: barcode.corners,
      size: barcode.size,
    );
  }

  /// Decoded text payload.
  final String value;

  /// Decoded payload bytes, when the platform reports them. Prefer these
  /// over [value] for binary or non-UTF-8 payloads.
  final Uint8List? rawBytes;

  /// Corners of the code in the camera image, clockwise from top-left.
  /// Empty when the platform does not report them.
  final List<Offset> corners;

  /// Size of the code's bounding box in the camera image.
  final Size size;

  @override
  bool operator ==(Object other) =>
      other is QrScanResult &&
      other.value == value &&
      listEquals(other.rawBytes, rawBytes) &&
      listEquals(other.corners, corners) &&
      other.size == size;

  @override
  int get hashCode => Object.hash(
    value,
    rawBytes == null ? null : Object.hashAll(rawBytes!),
    Object.hashAll(corners),
    size,
  );

  @override
  String toString() => 'QrScanResult($value)';
}

/// Drops repeated sightings of the same code.
///
/// A camera reports a code on every frame it stays in view. A value is
/// accepted once, then ignored until it has been out of view for [cooldown].
class QrScanDeduplicator {
  /// Creates a deduplicator.
  QrScanDeduplicator({required this.cooldown});

  /// How long a value must go unseen before it is accepted again.
  final Duration cooldown;

  String? _lastValue;
  DateTime? _lastSeen;

  /// Whether [value], seen at [now], is a new scan.
  bool accept(String value, DateTime now) {
    final duplicate =
        value == _lastValue &&
        _lastSeen != null &&
        now.difference(_lastSeen!) < cooldown;
    _lastValue = value;
    _lastSeen = now;
    return !duplicate;
  }

  /// Forgets the last value, so the next sighting is always accepted.
  void reset() {
    _lastValue = null;
    _lastSeen = null;
  }
}
