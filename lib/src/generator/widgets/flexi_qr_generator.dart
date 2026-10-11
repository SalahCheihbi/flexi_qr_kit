import 'package:flutter/widgets.dart';

import '../../core/models/qr_error_correction_level.dart';
import '../encoder/qr_encoder.dart';
import '../encoder/qr_package_encoder.dart';
import '../matrix/qr_matrix.dart';
import '../styles/qr_design.dart';
import 'flexi_qr_painter.dart';

/// Builds a widget shown in place of the code when encoding fails.
typedef QrErrorWidgetBuilder =
    Widget Function(BuildContext context, Object error);

/// Encodes [data] and draws it as a styled QR code.
///
/// ```dart
/// FlexiQrGenerator(
///   data: 'https://example.com',
///   size: 240,
///   design: QrDesign(
///     moduleStyle: QrModuleStyle(
///       shape: QrModuleShape.custom,
///       borderRadius: BorderRadius.only(
///         topLeft: Radius.circular(8),
///         topRight: Radius.circular(8),
///         bottomRight: Radius.circular(8),
///         bottomLeft: Radius.zero,
///       ),
///     ),
///   ),
/// )
/// ```
class FlexiQrGenerator extends StatefulWidget {
  /// Creates a QR code widget.
  const FlexiQrGenerator({
    super.key,
    required this.data,
    this.design = const QrDesign(),
    this.errorCorrectionLevel = QrErrorCorrectionLevel.medium,
    this.version,
    this.size,
    this.encoder = const QrPackageEncoder(),
    this.errorBuilder,
    this.semanticLabel = 'QR code',
  });

  /// Payload to encode, as UTF-8.
  final String data;

  /// Visual configuration.
  final QrDesign design;

  /// Error correction level.
  final QrErrorCorrectionLevel errorCorrectionLevel;

  /// Fixed QR version (1 to 40), or `null` for the smallest that fits.
  final int? version;

  /// Side length including the quiet zone. When null, the code fills the
  /// largest square that fits the incoming constraints, or 200 when
  /// unconstrained.
  final double? size;

  /// Encoder implementation, replaceable for testing or other libraries.
  final QrEncoder encoder;

  /// Shown when encoding fails. When null, the error is thrown during build.
  final QrErrorWidgetBuilder? errorBuilder;

  /// Accessibility label.
  final String semanticLabel;

  @override
  State<FlexiQrGenerator> createState() => _FlexiQrGeneratorState();
}

class _FlexiQrGeneratorState extends State<FlexiQrGenerator> {
  static const double _fallbackSize = 200;

  QrMatrix? _matrix;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    _encode();
  }

  @override
  void didUpdateWidget(FlexiQrGenerator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.errorCorrectionLevel != widget.errorCorrectionLevel ||
        oldWidget.version != widget.version ||
        oldWidget.encoder != widget.encoder) {
      _encode();
    }
  }

  void _encode() {
    try {
      _matrix = widget.encoder.encode(
        widget.data,
        errorCorrectionLevel: widget.errorCorrectionLevel,
        version: widget.version,
      );
      _error = null;
      _stackTrace = null;
    } catch (e, st) {
      _matrix = null;
      _error = e;
      _stackTrace = st;
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      final builder = widget.errorBuilder;
      if (builder == null) Error.throwWithStackTrace(error, _stackTrace!);
      return builder(context, error);
    }

    final painter = FlexiQrPainter(matrix: _matrix!, design: widget.design);
    Widget square(double side) => SizedBox.square(
      dimension: side,
      child: CustomPaint(painter: painter),
    );

    final size = widget.size;
    final Widget child;
    if (size != null) {
      child = square(size);
    } else {
      child = LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final side = w.isFinite || h.isFinite
              ? (w < h ? w : h)
              : _fallbackSize;
          return Center(child: square(side));
        },
      );
    }

    return Semantics(label: widget.semanticLabel, image: true, child: child);
  }
}
