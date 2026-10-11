import 'dart:typed_data';

import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingEncoder implements QrEncoder {
  int calls = 0;

  @override
  QrMatrix encode(
    String data, {
    QrErrorCorrectionLevel errorCorrectionLevel = QrErrorCorrectionLevel.medium,
    int? version,
  }) {
    calls++;
    return const QrPackageEncoder().encode(
      data,
      errorCorrectionLevel: errorCorrectionLevel,
      version: version,
    );
  }

  @override
  QrMatrix encodeBytes(
    Uint8List bytes, {
    QrErrorCorrectionLevel errorCorrectionLevel = QrErrorCorrectionLevel.medium,
    int? version,
  }) => throw UnimplementedError();
}

Widget _app(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

FlexiQrPainter _painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<FlexiQrPainter>()
    .single;

void main() {
  group('FlexiQrGenerator', () {
    testWidgets('paints the encoded data at the requested size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const Center(child: FlexiQrGenerator(data: 'hello', size: 150))),
      );
      expect(
        tester.getSize(find.byType(FlexiQrGenerator)),
        const Size(150, 150),
      );
      expect(_painter(tester).matrix, const QrPackageEncoder().encode('hello'));
    });

    testWidgets('fills the available square when size is null', (tester) async {
      await tester.pumpWidget(
        _app(
          const Center(
            child: SizedBox(
              width: 300,
              height: 200,
              child: FlexiQrGenerator(data: 'hello'),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(CustomPaint).last),
        const Size(200, 200),
      );
    });

    testWidgets('passes the design to the painter', (tester) async {
      const design = QrDesign(
        moduleStyle: QrModuleStyle(shape: QrModuleShape.dots),
      );
      await tester.pumpWidget(
        _app(
          const Center(
            child: FlexiQrGenerator(data: 'x', size: 100, design: design),
          ),
        ),
      );
      expect(_painter(tester).design, design);
    });

    testWidgets('re-encodes only when encoding inputs change', (tester) async {
      final encoder = _CountingEncoder();
      Widget build(String data, {Color bg = Colors.white}) => Center(
        child: FlexiQrGenerator(
          data: data,
          size: 100,
          encoder: encoder,
          design: QrDesign(backgroundColor: bg),
        ),
      );

      await tester.pumpWidget(_app(build('a')));
      expect(encoder.calls, 1);
      await tester.pumpWidget(_app(build('a', bg: Colors.yellow)));
      expect(encoder.calls, 1, reason: 'design changes do not re-encode');
      await tester.pumpWidget(_app(build('b')));
      expect(encoder.calls, 2);
      expect(_painter(tester).matrix, const QrPackageEncoder().encode('b'));
    });

    testWidgets('re-encodes when the error correction level changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const Center(child: FlexiQrGenerator(data: 'a', size: 100))),
      );
      await tester.pumpWidget(
        _app(
          const Center(
            child: FlexiQrGenerator(
              data: 'a',
              size: 100,
              errorCorrectionLevel: QrErrorCorrectionLevel.high,
            ),
          ),
        ),
      );
      expect(
        _painter(tester).matrix.errorCorrectionLevel,
        QrErrorCorrectionLevel.high,
      );
    });

    testWidgets('shows errorBuilder when data does not fit', (tester) async {
      await tester.pumpWidget(
        _app(
          Directionality(
            textDirection: TextDirection.ltr,
            child: FlexiQrGenerator(
              data: 'a' * 5000,
              size: 100,
              errorBuilder: (context, error) =>
                  Text(error is QrDataTooLongException ? 'too long' : 'other'),
            ),
          ),
        ),
      );
      expect(find.text('too long'), findsOneWidget);
      expect(find.byType(CustomPaint), findsNothing);
    });

    testWidgets('reports the error when no errorBuilder is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(FlexiQrGenerator(data: 'a' * 5000, size: 100)),
      );
      expect(tester.takeException(), isA<QrDataTooLongException>());
    });

    testWidgets('exposes a semantics label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const Center(
            child: FlexiQrGenerator(
              data: 'x',
              size: 100,
              semanticLabel: 'Website QR',
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Website QR'), findsOneWidget);
      handle.dispose();
    });
  });

  group('FlexiQrPainter', () {
    test('repaints only when matrix or design change', () {
      final m = const QrPackageEncoder().encode('a');
      final p = FlexiQrPainter(matrix: m, design: const QrDesign());
      expect(
        p.shouldRepaint(FlexiQrPainter(matrix: m, design: const QrDesign())),
        isFalse,
      );
      expect(
        p.shouldRepaint(
          FlexiQrPainter(matrix: m, design: const QrDesign(quietZone: 2)),
        ),
        isTrue,
      );
      expect(
        p.shouldRepaint(
          FlexiQrPainter(
            matrix: const QrPackageEncoder().encode('b'),
            design: const QrDesign(),
          ),
        ),
        isTrue,
      );
    });
  });
}
