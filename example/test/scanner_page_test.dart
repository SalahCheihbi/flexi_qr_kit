import 'package:example/pages/scanner_page.dart';
import 'package:flexi_qr_kit/scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart'
    show Barcode, BarcodeCapture, MobileScanner;

import 'helpers.dart';

FlexiQrScanner _scanner(WidgetTester tester) =>
    tester.widget<FlexiQrScanner>(find.byType(FlexiQrScanner));

void _detect(WidgetTester tester, String value) =>
    tester.widget<MobileScanner>(find.byType(MobileScanner)).onDetect!(
      BarcodeCapture(
        barcodes: [Barcode(rawValue: value, format: BarcodeFormat.qrCode)],
      ),
    );

void main() {
  late MobileScannerController controller;

  setUp(() => controller = MobileScannerController(autoStart: false));
  tearDown(() => controller.dispose());

  Future<void> pumpPage(WidgetTester tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ScannerPage(controller: controller)),
      ),
    );
  }

  testWidgets('starts with bracket overlay restricted to the window', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(_scanner(tester).overlayStyle, OverlayPreset.brackets.style);
    expect(_scanner(tester).restrictToScanWindow, isTrue);
    expect(find.byType(QrScannerOverlay), findsOneWidget);
    expect(find.text('Point the camera at a QR code'), findsOneWidget);
  });

  testWidgets('every overlay preset applies its style', (tester) async {
    await pumpPage(tester);
    for (final preset in OverlayPreset.values) {
      final chip = find.byKey(Key('overlay-${preset.name}'));
      await tester.ensureVisible(chip);
      await tester.pump();
      await tester.tap(chip);
      await tester.pump();

      expect(_scanner(tester).overlayStyle, preset.style);
      expect(
        find.byType(QrScannerOverlay),
        preset.style == null ? findsNothing : findsOneWidget,
      );
    }
  });

  test('presets frame the window differently', () {
    final frames = OverlayPreset.values
        .map((p) => p.style?.frame)
        .whereType<QrScannerFrameStyle>()
        .toList();
    expect(frames.toSet(), hasLength(frames.length));
    expect(frames.any((f) => f.fullBorder), isTrue);
    expect(frames.any((f) => f.corners.length == 2), isTrue);
    expect(
      frames.any((f) => f.borderRadius.topLeft != f.borderRadius.topRight),
      isTrue,
    );
  });

  testWidgets('the window restriction can be turned off', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const Key('restrict')));
    await tester.pump();
    expect(_scanner(tester).restrictToScanWindow, isFalse);
    expect(
      tester.widget<MobileScanner>(find.byType(MobileScanner)).scanWindow,
      isNull,
    );
  });

  testWidgets('lists scans newest first, without duplicates', (tester) async {
    await pumpPage(tester);
    _detect(tester, 'first');
    _detect(tester, 'first');
    _detect(tester, 'second');
    await tester.pump();

    final titles = tester
        .widgetList<ListTile>(
          find.descendant(
            of: find.byKey(const Key('results')),
            matching: find.byType(ListTile),
          ),
        )
        .map((t) => (t.title! as Text).data)
        .toList();
    expect(titles, ['second', 'first']);
  });

  testWidgets('shows torch and camera controls', (tester) async {
    await pumpPage(tester);
    expect(find.byKey(const Key('torch')), findsOneWidget);
    expect(find.byIcon(Icons.flash_off), findsOneWidget);
    expect(find.byKey(const Key('switch-camera')), findsOneWidget);
  });
}
