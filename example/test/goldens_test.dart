@Tags(['golden'])
library;

import 'package:example/pages/gallery_page.dart';
import 'package:example/pages/scanner_page.dart';
import 'package:example/showcases.dart';
import 'package:flexi_qr_kit/scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _boundary = Key('golden');

Widget _frame(Widget child, {Size size = const Size(240, 240)}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Center(
    child: RepaintBoundary(
      key: _boundary,
      child: SizedBox.fromSize(size: size, child: child),
    ),
  ),
);

void main() {
  // Goldens are rendered with the test font and differ slightly between
  // platforms; regenerate them with `flutter test --update-goldens` on the
  // platform CI uses.
  group('showcase', () {
    // The encoding error card is text only; it is covered by widget tests.
    final drawn = showcases.where(
      (s) => s.outcome != ShowcaseOutcome.encodingError,
    );
    for (final showcase in drawn) {
      testWidgets(showcase.title, (tester) async {
        await tester.pumpWidget(_frame(showcaseQr(showcase)));
        if (showcase.design.logo != null) await settleAsync(tester);

        await expectLater(
          find.byKey(_boundary),
          matchesGoldenFile('goldens/showcase_${showcase.slug}.png'),
        );
      });
    }
  });

  group('scanner overlay', () {
    for (final preset in OverlayPreset.values) {
      final style = preset.style;
      if (style == null) continue;
      testWidgets(preset.label, (tester) async {
        await tester.pumpWidget(
          _frame(
            size: const Size(360, 480),
            Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFF3F51B5)),
                QrScannerOverlay(style: style),
              ],
            ),
          ),
        );
        await expectLater(
          find.byKey(_boundary),
          matchesGoldenFile('goldens/overlay_${preset.name}.png'),
        );
      });
    }
  });
}
