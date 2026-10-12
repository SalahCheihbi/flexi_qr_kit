import 'dart:typed_data';
import 'dart:ui';

import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  group('QrScanResult.fromBarcode', () {
    test('copies value, bytes, corners and size', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final result = QrScanResult.fromBarcode(
        Barcode(
          rawValue: 'hello',
          rawDecodedBytes: DecodedBarcodeBytes(bytes: bytes),
          format: BarcodeFormat.qrCode,
          corners: const [Offset(1, 2), Offset(3, 4)],
          size: const Size(10, 20),
        ),
      );
      expect(result.value, 'hello');
      expect(result.rawBytes, bytes);
      expect(result.corners, const [Offset(1, 2), Offset(3, 4)]);
      expect(result.size, const Size(10, 20));
    });

    test('equality is by value', () {
      const a = QrScanResult(value: 'x');
      const b = QrScanResult(value: 'x');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const QrScanResult(value: 'y')));
    });
  });

  group('QrScanDeduplicator', () {
    test('accepts a new value', () {
      final d = QrScanDeduplicator(cooldown: const Duration(seconds: 2));
      expect(d.accept('a', DateTime(2026)), isTrue);
    });

    test('rejects the same value within the cooldown', () {
      final d = QrScanDeduplicator(cooldown: const Duration(seconds: 2));
      final t = DateTime(2026);
      d.accept('a', t);
      expect(d.accept('a', t.add(const Duration(seconds: 1))), isFalse);
    });

    test('accepts the same value again after the cooldown', () {
      final d = QrScanDeduplicator(cooldown: const Duration(seconds: 2));
      final t = DateTime(2026);
      d.accept('a', t);
      expect(d.accept('a', t.add(const Duration(seconds: 3))), isTrue);
    });

    test('measures the cooldown from the last sighting', () {
      final d = QrScanDeduplicator(cooldown: const Duration(seconds: 2));
      final t = DateTime(2026);
      d.accept('a', t);
      d.accept('a', t.add(const Duration(seconds: 1)));
      // The code stayed in view, so it is still the same scan.
      expect(d.accept('a', t.add(const Duration(seconds: 2))), isFalse);
    });

    test('accepts a different value immediately', () {
      final d = QrScanDeduplicator(cooldown: const Duration(seconds: 2));
      final t = DateTime(2026);
      d.accept('a', t);
      expect(d.accept('b', t), isTrue);
    });

    test('a zero cooldown accepts everything', () {
      final d = QrScanDeduplicator(cooldown: Duration.zero);
      final t = DateTime(2026);
      expect(d.accept('a', t), isTrue);
      expect(d.accept('a', t), isTrue);
    });

    test('reset forgets the last value', () {
      final d = QrScanDeduplicator(cooldown: const Duration(seconds: 2));
      final t = DateTime(2026);
      d.accept('a', t);
      d.reset();
      expect(d.accept('a', t), isTrue);
    });
  });
}
