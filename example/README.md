# flexi_qr_kit example

Demo app for every `flexi_qr_kit` feature, in three tabs:

- **Gallery**: one card per feature (shapes, smart corners, colors and
  effects, finder styles, backgrounds, logos), plus codes that fail
  validation on purpose. Open a card to see its validation report and export
  it as a PNG.
- **Designer**: edit the payload, module shape, each corner radius, corner
  mode, scale, spacing, quiet zone, color, gradient, finder preset, logo and
  error correction, with live validation and PNG export.
- **Scanner**: live camera scanning with overlay presets (corner brackets,
  asymmetric radii, two corners only, full border, none), a switch for
  scanning only inside the window, torch and camera switching.

The gallery entries live in `lib/showcases.dart`.

## Run

```sh
fvm flutter run
```

Runs on Android, iOS, web, Windows and Linux. The scanner needs a camera
(Android, iOS and web). The camera permission is already set up for iOS
(`NSCameraUsageDescription`); on Android it comes from `mobile_scanner`.

## Tests

```sh
fvm flutter test                      # everything
fvm flutter test --exclude-tags golden
fvm flutter test --update-goldens     # after an intended visual change
```

- `showcases_test.dart` validates every gallery entry with `QrValidator` and
  checks it gets its expected outcome (valid, warning, invalid or encoding
  error).
- `gallery_test.dart`, `designer_test.dart`, `scanner_page_test.dart` and
  `app_test.dart` drive the UI.
- `screenshots_test.dart` regenerates the README screenshots in
  `../doc/screenshots/`; it is skipped unless you pass
  `--dart-define=UPDATE_SCREENSHOTS=true`.
- `goldens_test.dart` compares each showcase and overlay preset against
  `test/goldens/`. Font rendering differs between platforms, so generate
  goldens on the platform that checks them.
