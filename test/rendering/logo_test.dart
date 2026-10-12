import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _encoder = QrPackageEncoder();
const _red = Color(0xFFFF0000);
const _blue = Color(0xFF0000FF);
const _white = Color(0xFFFFFFFF);
const _black = Color(0xFF000000);
const _clear = Color(0x00000000);

// 1x1 transparent PNG, used where only the provider identity matters.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
]);

QrLogo _logo({
  double sizeFactor = 0.2,
  double padding = 0,
  Color? backgroundColor,
  BorderRadius borderRadius = BorderRadius.zero,
  bool clearModules = true,
  QrLogoRenderer? renderer,
}) => QrLogo(
  image: MemoryImage(_png),
  sizeFactor: sizeFactor,
  padding: padding,
  backgroundColor: backgroundColor,
  borderRadius: borderRadius,
  clearModules: clearModules,
  renderer: renderer,
);

Future<ui.Image> _solid(Color color, int size) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..color = color,
  );
  return recorder.endRecording().toImage(size, size);
}

class _Raster {
  _Raster(this.bytes, this.width);
  final ByteData bytes;
  final int width;

  Color at(num x, num y) {
    final i = (y.toInt() * width + x.toInt()) * 4;
    return Color.fromARGB(
      bytes.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
  }
}

Future<_Raster> _render(
  QrMatrix m,
  QrDesign d,
  int size, {
  ui.Image? logoImage,
}) async {
  final recorder = ui.PictureRecorder();
  QrRenderPipeline(
    matrix: m,
    design: d,
    logoImage: logoImage,
  ).paint(Canvas(recorder), Size.square(size.toDouble()));
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData();
  image.dispose();
  return _Raster(bytes!, size);
}

void main() {
  group('QrLogo', () {
    test('defaults', () {
      final logo = QrLogo(image: MemoryImage(_png));
      expect(logo.sizeFactor, 0.2);
      expect(logo.padding, 4);
      expect(logo.backgroundColor, isNull);
      expect(logo.borderRadius, BorderRadius.zero);
      expect(logo.clearModules, isTrue);
    });

    test('rejects out-of-range sizes and padding', () {
      expect(
        () => QrLogo(image: MemoryImage(_png), sizeFactor: 0),
        throwsAssertionError,
      );
      expect(
        () => QrLogo(image: MemoryImage(_png), sizeFactor: 0.5),
        throwsAssertionError,
      );
      expect(
        () => QrLogo(image: MemoryImage(_png), padding: -1),
        throwsAssertionError,
      );
    });
  });

  group('QrLogoLayout', () {
    // Version 3: 29 modules. 290 px with no quiet zone -> 10 px per module.
    final layout = QrRenderLayout.compute(const Size.square(290), 29, 0);

    test('snaps to an odd number of whole modules, centered', () {
      final l = QrLogoLayout.compute(layout, 29, _logo(sizeFactor: 0.2))!;
      // round(0.2 * 29) = 6 -> next odd = 7 modules.
      expect(l.moduleCount, 7);
      expect(l.firstModule, 11);
      expect(l.containerRect, const Rect.fromLTWH(110, 110, 70, 70));
    });

    test('never reaches the finder patterns', () {
      final l = QrLogoLayout.compute(layout, 29, _logo(sizeFactor: 0.4))!;
      // 29 - 16 = 13: leaves the 8x8 finder corners free.
      expect(l.moduleCount, 13);
      final v1 = QrRenderLayout.compute(const Size.square(210), 21, 0);
      expect(
        QrLogoLayout.compute(v1, 21, _logo(sizeFactor: 0.4))!.moduleCount,
        5,
      );
    });

    test('padding shrinks the image area', () {
      final l = QrLogoLayout.compute(layout, 29, _logo(padding: 5))!;
      expect(l.imageRect, l.containerRect.deflate(5));
    });

    test('coversModule matches the snapped square', () {
      final l = QrLogoLayout.compute(layout, 29, _logo())!;
      expect(l.coversModule(11, 11), isTrue);
      expect(l.coversModule(17, 17), isTrue);
      expect(l.coversModule(10, 14), isFalse);
      expect(l.coversModule(14, 18), isFalse);
    });
  });

  group('logo rendering', () {
    // Version 3 (29 modules) + no quiet zone at 290 px -> 10 px per module.
    final m = _encoder.encode('logo test payload', version: 3);
    QrDesign design(QrLogo logo, {Color bg = _white}) =>
        QrDesign(quietZone: 0, backgroundColor: bg, logo: logo);

    test('draws the image centered on the code', () async {
      final image = await _solid(_red, 8);
      final r = await _render(m, design(_logo()), 290, logoImage: image);
      expect(r.at(145, 145), _red);
      expect(r.at(5, 5), _black, reason: 'finder untouched');
    });

    test('container fills behind the logo with its background', () async {
      final r = await _render(m, design(_logo(backgroundColor: _blue)), 290);
      expect(r.at(145, 145), _blue, reason: 'shown while the image loads');
    });

    test('rounded container leaves its corners to the code', () async {
      final r = await _render(
        m,
        design(
          _logo(
            backgroundColor: _blue,
            borderRadius: BorderRadius.circular(999),
            clearModules: false,
          ),
        ),
        290,
      );
      expect(r.at(145, 145), _blue);
      expect(r.at(111, 111), isNot(_blue), reason: 'circle corner');
    });

    test('clears data modules under the container', () async {
      // Transparent container background exposes what is underneath.
      Future<int> darkUnderLogo({required bool clear}) async {
        final r = await _render(
          m,
          design(
            _logo(backgroundColor: _clear, clearModules: clear),
            bg: _white,
          ),
          290,
        );
        var dark = 0;
        for (var row = 11; row < 18; row++) {
          for (var col = 11; col < 18; col++) {
            if (m.typeAt(row, col) != QrModuleType.data) continue;
            if (r.at(col * 10 + 5, row * 10 + 5) == _black) dark++;
          }
        }
        return dark;
      }

      expect(await darkUnderLogo(clear: false), greaterThan(0));
      expect(await darkUnderLogo(clear: true), 0);
    });

    test('never clears protected modules', () async {
      // Version 7 has an alignment pattern at the center (row/col 22).
      final v7 = _encoder.encode('x', version: 7);
      expect(v7.typeAt(22, 22), QrModuleType.alignment);
      final r = await _render(
        v7,
        QrDesign(
          quietZone: 0,
          logo: _logo(backgroundColor: _clear, sizeFactor: 0.3),
        ),
        450,
      );
      // 45 modules at 450 px -> 10 px per module.
      expect(r.at(22 * 10 + 5, 22 * 10 + 5), _black);
    });

    test('custom renderer receives the logo geometry', () async {
      final spy = _SpyLogoRenderer();
      final image = await _solid(_red, 4);
      QrRenderPipeline(
        matrix: m,
        design: design(_logo(renderer: spy, padding: 2)),
        logoImage: image,
      ).paint(Canvas(ui.PictureRecorder()), const Size.square(290));
      final g = spy.received!;
      expect(g.containerRect, const Rect.fromLTWH(110, 110, 70, 70));
      expect(g.imageRect, const Rect.fromLTWH(112, 112, 66, 66));
      expect(g.image, same(image));
      expect(g.logo.padding, 2);
    });
  });
}

class _SpyLogoRenderer extends QrLogoRenderer {
  QrLogoGeometry? received;

  @override
  void paint(Canvas canvas, QrLogoGeometry geometry) => received = geometry;
}
