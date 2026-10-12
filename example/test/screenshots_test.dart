/// Regenerates the README screenshots in `../doc/screenshots`:
///
/// ```sh
/// fvm flutter test test/screenshots_test.dart --dart-define=UPDATE_SCREENSHOTS=true
/// ```
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:example/pages/scanner_page.dart';
import 'package:example/showcases.dart';
import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flexi_qr_kit/scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _update = bool.fromEnvironment('UPDATE_SCREENSHOTS');
const _skip = _update ? false : 'Pass --dart-define=UPDATE_SCREENSHOTS=true';
final _out = Directory('../doc/screenshots');

Future<ui.Image> _logo() async {
  final codec = await ui.instantiateImageCodec(
    File('assets/logo.png').readAsBytesSync(),
  );
  return (await codec.getNextFrame()).image;
}

Future<void> _save(ui.Image image, String name) async {
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  _out.createSync(recursive: true);
  File('${_out.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  image.dispose();
}

void main() {
  group('showcase', () {
    final drawn = showcases.where(
      (s) => s.outcome != ShowcaseOutcome.encodingError,
    );
    for (final showcase in drawn) {
      test(showcase.title, skip: _skip, () async {
        final design = showcase.design;
        final matrix = const QrPackageEncoder().encode(
          showcase.data,
          errorCorrectionLevel:
              showcase.errorCorrectionLevel ??
              design.defaultErrorCorrectionLevel,
        );
        final image = await renderQrImage(
          matrix: matrix,
          design: design,
          size: 240,
          pixelRatio: 2,
          logoImage: design.logo == null ? null : await _logo(),
        );
        await _save(image, showcase.slug);
      });
    }
  });

  group('scanner overlay', () {
    for (final preset in OverlayPreset.values) {
      final style = preset.style;
      if (style == null) continue;
      testWidgets(preset.label, skip: !_update, (tester) async {
        const key = Key('shot');
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 300,
                  height: 400,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0xFF5D6B7A)),
                      const Center(
                        child: FlexiQrGenerator(
                          data: 'https://pub.dev/packages/flexi_qr_kit',
                          size: 170,
                          design: QrDesign(
                            moduleStyle: QrModuleStyle(
                              shape: QrModuleShape.smooth,
                            ),
                          ),
                        ),
                      ),
                      QrScannerOverlay(
                        style: style.copyWith(
                          windowSize: Size(
                            220,
                            preset == OverlayPreset.fullBorder ? 200 : 220,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        await tester.runAsync(() async {
          await _save(
            await boundary.toImage(pixelRatio: 2),
            'overlay_${preset.name}',
          );
        });
      });
    }
  });
}
