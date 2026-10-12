/// Camera QR scanner for `flexi_qr_kit`, built on `mobile_scanner`, with a
/// customizable overlay.
///
/// Supports Android, iOS, macOS and web. Add the camera permission your
/// platforms require, as the `mobile_scanner` documentation describes.
library;

export 'package:mobile_scanner/mobile_scanner.dart'
    show
        BarcodeFormat,
        CameraFacing,
        DetectionSpeed,
        MobileScannerController,
        MobileScannerErrorCode,
        MobileScannerException,
        TorchState;

export 'src/core/models/qr_corner.dart';
export 'src/scanner/flexi_qr_scanner.dart';
export 'src/scanner/qr_scan_result.dart';
export 'src/scanner/qr_scanner_overlay.dart';
export 'src/scanner/qr_scanner_overlay_style.dart';
