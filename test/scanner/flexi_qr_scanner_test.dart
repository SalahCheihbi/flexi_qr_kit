import 'package:flexi_qr_kit/scanner.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(child: SizedBox(width: 400, height: 600, child: child)),
);

MobileScanner _scanner(WidgetTester tester) =>
    tester.widget<MobileScanner>(find.byType(MobileScanner));

void _detect(WidgetTester tester, List<Barcode> barcodes) =>
    _scanner(tester).onDetect!(BarcodeCapture(barcodes: barcodes));

Barcode _qr(String value) =>
    Barcode(rawValue: value, format: BarcodeFormat.qrCode);

void main() {
  late MobileScannerController controller;

  setUp(() => controller = MobileScannerController(autoStart: false));
  tearDown(() => controller.dispose());

  testWidgets('restricts detection to the overlay window', (tester) async {
    await tester.pumpWidget(
      _host(
        FlexiQrScanner(
          controller: controller,
          onDetect: (_) {},
          overlayStyle: const QrScannerOverlayStyle(windowSize: Size(200, 200)),
        ),
      ),
    );
    expect(
      _scanner(tester).scanWindow,
      const Rect.fromLTWH(100, 200, 200, 200),
    );
    expect(find.byType(QrScannerOverlay), findsOneWidget);
  });

  testWidgets('scans the whole preview when not restricted', (tester) async {
    await tester.pumpWidget(
      _host(
        FlexiQrScanner(
          controller: controller,
          onDetect: (_) {},
          restrictToScanWindow: false,
        ),
      ),
    );
    expect(_scanner(tester).scanWindow, isNull);
  });

  testWidgets('draws no overlay when the style is null', (tester) async {
    await tester.pumpWidget(
      _host(
        FlexiQrScanner(
          controller: controller,
          onDetect: (_) {},
          overlayStyle: null,
        ),
      ),
    );
    expect(find.byType(QrScannerOverlay), findsNothing);
    expect(_scanner(tester).scanWindow, isNull);
  });

  testWidgets('reports QR codes and drops duplicates', (tester) async {
    final results = <QrScanResult>[];
    await tester.pumpWidget(
      _host(FlexiQrScanner(controller: controller, onDetect: results.add)),
    );

    _detect(tester, [_qr('a')]);
    _detect(tester, [_qr('a')]);
    _detect(tester, [_qr('b')]);

    expect(results.map((r) => r.value), ['a', 'b']);
  });

  testWidgets('reports every sighting with a zero cooldown', (tester) async {
    final results = <QrScanResult>[];
    await tester.pumpWidget(
      _host(
        FlexiQrScanner(
          controller: controller,
          onDetect: results.add,
          duplicateCooldown: Duration.zero,
        ),
      ),
    );

    _detect(tester, [_qr('a')]);
    _detect(tester, [_qr('a')]);

    expect(results, hasLength(2));
  });

  testWidgets('ignores other formats and empty values', (tester) async {
    final results = <QrScanResult>[];
    await tester.pumpWidget(
      _host(FlexiQrScanner(controller: controller, onDetect: results.add)),
    );

    _detect(tester, [
      const Barcode(rawValue: '123', format: BarcodeFormat.ean13),
      const Barcode(format: BarcodeFormat.qrCode),
    ]);

    expect(results, isEmpty);
  });

  testWidgets('does not dispose a controller it does not own', (tester) async {
    await tester.pumpWidget(
      _host(FlexiQrScanner(controller: controller, onDetect: (_) {})),
    );
    await tester.pumpWidget(const SizedBox());
    // A disposed notifier throws when a listener is added.
    expect(() => controller.addListener(() {}), returnsNormally);
  });
}
