import 'dart:convert';
import 'dart:typed_data';

import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr/qr.dart' as qr;

const _encoder = QrPackageEncoder();

void main() {
  group('QrPackageEncoder', () {
    test('produces exactly the modules of the reference encoder', () {
      const data = 'https://example.com/path?q=1';
      final reference = qr.QrImage(
        qr.QrCode.fromData(
          data: data,
          errorCorrectLevel: qr.QrErrorCorrectLevel.Q,
        ),
      );
      final m = _encoder.encode(
        data,
        errorCorrectionLevel: QrErrorCorrectionLevel.quartile,
      );
      expect(m.size, reference.moduleCount);
      for (var r = 0; r < m.size; r++) {
        for (var c = 0; c < m.size; c++) {
          expect(m.isDark(r, c), reference.isDark(r, c));
        }
      }
    });

    test('defaults to error correction level medium', () {
      expect(
        _encoder.encode('abc').errorCorrectionLevel,
        QrErrorCorrectionLevel.medium,
      );
    });

    test('is deterministic', () {
      expect(_encoder.encode('same'), _encoder.encode('same'));
    });

    test('picks the smallest version that fits', () {
      expect(_encoder.encode('a').version, 1);
      expect(_encoder.encode('a' * 100).version, greaterThan(1));
    });

    test('higher error correction needs a larger or equal version', () {
      final data = 'x' * 60;
      final low = _encoder.encode(
        data,
        errorCorrectionLevel: QrErrorCorrectionLevel.low,
      );
      final high = _encoder.encode(
        data,
        errorCorrectionLevel: QrErrorCorrectionLevel.high,
      );
      expect(high.version, greaterThan(low.version));
    });

    test('honors a fixed version', () {
      expect(_encoder.encode('a', version: 10).size, 57);
    });

    test('rejects versions outside 1..40', () {
      expect(() => _encoder.encode('a', version: 0), throwsArgumentError);
      expect(() => _encoder.encode('a', version: 41), throwsArgumentError);
    });

    test('throws QrDataTooLongException when data does not fit', () {
      expect(
        () => _encoder.encode(
          'a' * 3000,
          errorCorrectionLevel: QrErrorCorrectionLevel.high,
        ),
        throwsA(isA<QrDataTooLongException>()),
      );
      expect(
        () => _encoder.encode('a' * 100, version: 1),
        throwsA(isA<QrDataTooLongException>()),
      );
    });

    test('encodes Unicode and Arabic text as UTF-8 bytes', () {
      const arabic = 'مرحبا بالعالم';
      const mixed = 'héllo 世界 🚀';
      // Same matrix as encoding the UTF-8 bytes directly.
      expect(
        _encoder.encode(arabic),
        _encoder.encodeBytes(Uint8List.fromList(utf8.encode(arabic))),
      );
      expect(
        _encoder.encode(mixed),
        _encoder.encodeBytes(Uint8List.fromList(utf8.encode(mixed))),
      );
    });

    test('encodes raw byte payloads', () {
      final m = _encoder.encodeBytes(Uint8List.fromList([0, 1, 2, 255]));
      expect(m.version, 1);
    });

    test('encodes an empty payload', () {
      expect(_encoder.encode('').version, 1);
    });
  });
}
