import 'package:example/main.dart';
import 'package:example/pages/designer_page.dart';
import 'package:example/pages/gallery_page.dart';
import 'package:example/pages/scanner_page.dart';
import 'package:flexi_qr_kit/scanner.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('navigates between gallery, designer and scanner', (
    tester,
  ) async {
    usePhoneSize(tester);
    final controller = MobileScannerController(autoStart: false);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      FlexiQrExampleApp(
        scannerBuilder: (_) => ScannerPage(controller: controller),
      ),
    );
    expect(find.byType(GalleryPage), findsOneWidget);
    expect(find.text('flexi_qr_kit · Gallery'), findsOneWidget);

    await tester.tap(find.text('Designer'));
    await tester.pump();
    expect(find.byType(DesignerPage), findsOneWidget);
    expect(find.byType(GalleryPage), findsNothing);

    await tester.tap(find.text('Scanner'));
    await tester.pump();
    expect(find.byType(ScannerPage), findsOneWidget);
    expect(find.byType(FlexiQrScanner), findsOneWidget);

    await tester.tap(find.text('Gallery'));
    await tester.pump();
    expect(find.byType(GalleryPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
