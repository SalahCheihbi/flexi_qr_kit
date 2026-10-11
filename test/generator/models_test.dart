import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QrModuleType', () {
    test('only data modules are unprotected', () {
      for (final type in QrModuleType.values) {
        expect(type.isProtected, type != QrModuleType.data, reason: '$type');
      }
    });
  });

  group('QrNeighbors', () {
    test('defaults to no dark neighbors', () {
      const n = QrNeighbors();
      expect(n.top || n.bottom || n.left || n.right, isFalse);
      expect(n.topLeft || n.topRight || n.bottomLeft || n.bottomRight, isFalse);
      expect(n.orthogonalCount, 0);
    });

    test('orthogonalCount counts only the four direct neighbors', () {
      const n = QrNeighbors(top: true, left: true, topLeft: true);
      expect(n.orthogonalCount, 2);
    });

    test('value equality', () {
      expect(const QrNeighbors(top: true), const QrNeighbors(top: true));
      expect(const QrNeighbors(top: true), isNot(const QrNeighbors()));
    });
  });

  group('QrModuleContext', () {
    test('exposes position, state and protection', () {
      const ctx = QrModuleContext(
        row: 3,
        col: 4,
        isDark: true,
        type: QrModuleType.timing,
        neighbors: QrNeighbors(right: true),
      );
      expect(ctx.row, 3);
      expect(ctx.col, 4);
      expect(ctx.isDark, isTrue);
      expect(ctx.isProtected, isTrue);
      expect(ctx.neighbors.right, isTrue);
    });
  });

  group('QrErrorCorrectionLevel', () {
    test('has the four standard levels in increasing strength', () {
      expect(QrErrorCorrectionLevel.values, [
        QrErrorCorrectionLevel.low,
        QrErrorCorrectionLevel.medium,
        QrErrorCorrectionLevel.quartile,
        QrErrorCorrectionLevel.high,
      ]);
      expect(QrErrorCorrectionLevel.high.recoveryCapacity, 0.30);
    });
  });

  group('QrModuleStyle', () {
    test('defaults to opaque black squares filling the cell', () {
      const s = QrModuleStyle();
      expect(s.shape, QrModuleShape.square);
      expect(s.color, const Color(0xFF000000));
      expect(s.opacity, 1);
      expect(s.scale, 1);
      expect(s.spacing, 0);
      expect(s.rotation, 0);
      expect(s.borderRadius, isNull);
      expect(s.gradient, isNull);
      expect(s.renderer, isNull);
    });

    test('accepts independent corner radii', () {
      const s = QrModuleStyle(
        shape: QrModuleShape.custom,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
          bottomLeft: Radius.zero,
        ),
      );
      expect(s.borderRadius!.bottomLeft, Radius.zero);
      expect(s.borderRadius!.topLeft, const Radius.circular(8));
    });

    test('rejects invalid opacity, scale and spacing', () {
      expect(() => QrModuleStyle(opacity: 1.5), throwsAssertionError);
      expect(() => QrModuleStyle(scale: 0), throwsAssertionError);
      expect(() => QrModuleStyle(scale: 1.1), throwsAssertionError);
      expect(() => QrModuleStyle(spacing: -1), throwsAssertionError);
    });

    test('copyWith replaces only given fields', () {
      const s = QrModuleStyle(shape: QrModuleShape.dots, scale: 0.8);
      final c = s.copyWith(color: Colors.red);
      expect(c.shape, QrModuleShape.dots);
      expect(c.scale, 0.8);
      expect(c.color, Colors.red);
    });

    test('value equality (used to batch identical styles)', () {
      expect(
        const QrModuleStyle(shape: QrModuleShape.rounded),
        const QrModuleStyle(shape: QrModuleShape.rounded),
      );
      expect(
        const QrModuleStyle(shape: QrModuleShape.rounded).hashCode,
        const QrModuleStyle(shape: QrModuleShape.rounded).hashCode,
      );
      expect(
        const QrModuleStyle(shape: QrModuleShape.rounded),
        isNot(const QrModuleStyle(shape: QrModuleShape.dots)),
      );
    });
  });

  group('QrDesign', () {
    test('has scanner-friendly defaults', () {
      const d = QrDesign();
      expect(d.moduleStyle, const QrModuleStyle());
      expect(d.backgroundColor, const Color(0xFFFFFFFF));
      expect(d.quietZone, 4);
      expect(d.moduleBuilder, isNull);
    });

    test('resolves per-module styles through moduleBuilder', () {
      const ctx = QrModuleContext(
        row: 0,
        col: 0,
        isDark: true,
        type: QrModuleType.data,
        neighbors: QrNeighbors(),
      );
      const red = QrModuleStyle(color: Color(0xFFFF0000));
      final d = QrDesign(moduleBuilder: (m) => m.row == 0 ? red : null);
      expect(d.styleFor(ctx), red);
      expect(
        d.styleFor(
          const QrModuleContext(
            row: 1,
            col: 0,
            isDark: true,
            type: QrModuleType.data,
            neighbors: QrNeighbors(),
          ),
        ),
        d.moduleStyle,
      );
    });

    test('rejects a negative quiet zone', () {
      expect(() => QrDesign(quietZone: -1), throwsAssertionError);
    });
  });
}
