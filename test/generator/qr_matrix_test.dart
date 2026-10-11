import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter_test/flutter_test.dart';

const _encoder = QrPackageEncoder();

List<List<bool>> _blank(int size) =>
    List.generate(size, (_) => List.filled(size, false));

/// Number of data + error-correction modules (remainder bits included) for a
/// version, per ISO/IEC 18004. Independent of the classifier under test.
int _expectedDataModules(int v) {
  var result = (16 * v + 128) * v + 64;
  if (v >= 2) {
    final numAlign = v ~/ 7 + 2;
    result -= (25 * numAlign - 10) * numAlign - 55;
    if (v >= 7) result -= 36;
  }
  return result;
}

int _chebyshev(int r1, int c1, int r2, int c2) {
  final dr = (r1 - r2).abs();
  final dc = (c1 - c2).abs();
  return dr > dc ? dr : dc;
}

void main() {
  group('QrMatrix.fromModules', () {
    test('exposes size, version and module states', () {
      final rows = _blank(21)..[0][0] = true;
      final m = QrMatrix.fromModules(rows);
      expect(m.size, 21);
      expect(m.version, 1);
      expect(m.isDark(0, 0), isTrue);
      expect(m.isDark(0, 1), isFalse);
    });

    test('rejects non-square input', () {
      final rows = _blank(21)..[3] = List.filled(20, false);
      expect(() => QrMatrix.fromModules(rows), throwsArgumentError);
    });

    test('rejects sizes that are not a QR version', () {
      expect(() => QrMatrix.fromModules(_blank(22)), throwsArgumentError);
      expect(() => QrMatrix.fromModules(_blank(17)), throwsArgumentError);
      expect(() => QrMatrix.fromModules(_blank(181)), throwsArgumentError);
    });

    test('copies its input so later mutation has no effect', () {
      final rows = _blank(21);
      final m = QrMatrix.fromModules(rows);
      rows[10][10] = true;
      expect(m.isDark(10, 10), isFalse);
    });

    test('out-of-bounds modules are light', () {
      final m = QrMatrix.fromModules(
        List.generate(21, (_) => List.filled(21, true)),
      );
      expect(m.isDark(-1, 0), isFalse);
      expect(m.isDark(0, -1), isFalse);
      expect(m.isDark(21, 0), isFalse);
      expect(m.isDark(0, 21), isFalse);
    });

    test('typeAt rejects out-of-bounds coordinates', () {
      final m = QrMatrix.fromModules(_blank(21));
      expect(() => m.typeAt(21, 0), throwsRangeError);
    });

    test('value equality', () {
      expect(
        QrMatrix.fromModules(_blank(21)),
        QrMatrix.fromModules(_blank(21)),
      );
      expect(
        QrMatrix.fromModules(_blank(21)).hashCode,
        QrMatrix.fromModules(_blank(21)).hashCode,
      );
      expect(
        QrMatrix.fromModules(_blank(21)),
        isNot(QrMatrix.fromModules(_blank(21)..[9][9] = true)),
      );
    });
  });

  group('QrMatrix module context', () {
    final m = _encoder.encode('https://example.com');

    test('neighbors mirror isDark of the 8 surrounding modules', () {
      for (var r = 0; r < m.size; r++) {
        for (var c = 0; c < m.size; c++) {
          final n = m.moduleAt(r, c).neighbors;
          expect(n.top, m.isDark(r - 1, c));
          expect(n.bottom, m.isDark(r + 1, c));
          expect(n.left, m.isDark(r, c - 1));
          expect(n.right, m.isDark(r, c + 1));
          expect(n.topLeft, m.isDark(r - 1, c - 1));
          expect(n.topRight, m.isDark(r - 1, c + 1));
          expect(n.bottomLeft, m.isDark(r + 1, c - 1));
          expect(n.bottomRight, m.isDark(r + 1, c + 1));
        }
      }
    });

    test('modules iterates every module in row-major order', () {
      final all = m.modules.toList();
      expect(all.length, m.size * m.size);
      expect(all.first.row, 0);
      expect(all.first.col, 0);
      expect(all[1].col, 1);
      expect(all.last.row, m.size - 1);
      expect(all.last.col, m.size - 1);
      expect(all[m.size + 2], m.moduleAt(1, 2));
    });

    test('corner of the top-left finder is a dark protected module', () {
      final ctx = m.moduleAt(0, 0);
      expect(ctx.isDark, isTrue);
      expect(ctx.type, QrModuleType.finder);
      expect(ctx.isProtected, isTrue);
      expect(ctx.neighbors.top, isFalse);
      expect(ctx.neighbors.right, isTrue);
    });
  });

  group('matrix classification (all 40 versions)', () {
    for (var version = 1; version <= 40; version++) {
      test('version $version', () {
        final m = _encoder.encode('flexi', version: version);
        final n = m.size;
        expect(n, 17 + 4 * version);
        expect(m.version, version);

        final counts = <QrModuleType, int>{};
        final alignmentCenters = <(int, int)>[];
        for (var r = 0; r < n; r++) {
          for (var c = 0; c < n; c++) {
            final t = m.typeAt(r, c);
            counts[t] = (counts[t] ?? 0) + 1;
            final dark = m.isDark(r, c);

            switch (t) {
              case QrModuleType.finder:
                final cr = r < 7 ? 3 : n - 4;
                final cc = c < 7 ? 3 : n - 4;
                expect(dark, _chebyshev(r, c, cr, cc) != 2, reason: '($r,$c)');
              case QrModuleType.separator:
                expect(dark, isFalse, reason: '($r,$c)');
              case QrModuleType.timing:
                expect(dark, (r + c).isEven, reason: '($r,$c)');
              case QrModuleType.darkModule:
                expect((r, c), (n - 8, 8));
                expect(dark, isTrue);
              case QrModuleType.alignment:
                if (dark &&
                    m.isDark(r - 1, c) == false &&
                    m.isDark(r + 1, c) == false &&
                    m.isDark(r, c - 1) == false &&
                    m.isDark(r, c + 1) == false) {
                  alignmentCenters.add((r, c));
                }
              case QrModuleType.formatInfo ||
                  QrModuleType.versionInfo ||
                  QrModuleType.data:
                break;
            }
          }
        }

        expect(counts[QrModuleType.finder], 3 * 49);
        expect(counts[QrModuleType.separator], 3 * 15);
        expect(counts[QrModuleType.formatInfo], 30);
        expect(counts[QrModuleType.darkModule], 1);
        expect(counts[QrModuleType.versionInfo] ?? 0, version >= 7 ? 36 : 0);
        expect(counts[QrModuleType.data], _expectedDataModules(version));

        // Each alignment pattern is a dark center ringed by light then dark.
        final k = version == 1 ? 0 : version ~/ 7 + 2;
        expect(alignmentCenters.length, version == 1 ? 0 : k * k - 3);
        for (final (cr, cc) in alignmentCenters) {
          for (var dr = -2; dr <= 2; dr++) {
            for (var dc = -2; dc <= 2; dc++) {
              expect(m.typeAt(cr + dr, cc + dc), QrModuleType.alignment);
              expect(m.isDark(cr + dr, cc + dc), _chebyshev(0, 0, dr, dc) != 1);
            }
          }
        }
      });
    }
  });

  group('format information', () {
    // Reads the 15 format bits of both copies (bit 14 first), using the
    // module placement defined by ISO/IEC 18004 section 7.9.
    (int, int) readFormatBits(QrMatrix m) {
      final n = m.size;
      bool bit(int r, int c) => m.isDark(r, c);
      final a = <bool>[
        for (var i = 0; i <= 5; i++) bit(i, 8),
        bit(7, 8),
        bit(8, 8),
        bit(8, 7),
        for (var i = 9; i < 15; i++) bit(8, 14 - i),
      ];
      final b = <bool>[
        for (var i = 0; i < 8; i++) bit(8, n - 1 - i),
        for (var i = 8; i < 15; i++) bit(n - 15 + i, 8),
      ];
      int toInt(List<bool> bits) {
        var v = 0;
        for (var i = 0; i < 15; i++) {
          if (bits[i]) v |= 1 << i;
        }
        return v;
      }

      return (toInt(a), toInt(b));
    }

    const expectedEcBits = {
      QrErrorCorrectionLevel.low: 1,
      QrErrorCorrectionLevel.medium: 0,
      QrErrorCorrectionLevel.quartile: 3,
      QrErrorCorrectionLevel.high: 2,
    };

    for (final level in QrErrorCorrectionLevel.values) {
      test('encodes level ${level.name} in both copies', () {
        final m = _encoder.encode('hello', errorCorrectionLevel: level);
        expect(m.errorCorrectionLevel, level);
        final (a, b) = readFormatBits(m);
        expect(a, b, reason: 'both format copies must match');
        expect((a ^ 0x5412) >> 13, expectedEcBits[level]);
      });
    }
  });
}
