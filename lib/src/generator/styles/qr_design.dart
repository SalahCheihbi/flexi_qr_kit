import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../core/models/qr_module_context.dart';
import 'qr_module_style.dart';

/// Returns a style for one dark module, or `null` to use
/// [QrDesign.moduleStyle].
typedef QrModuleStyleBuilder = QrModuleStyle? Function(QrModuleContext module);

/// Complete visual description of a QR code.
///
/// The design never changes the encoded matrix. It only controls how the
/// matrix is drawn.
@immutable
class QrDesign {
  /// Creates a design.
  const QrDesign({
    this.moduleStyle = const QrModuleStyle(),
    this.moduleBuilder,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.quietZone = 4,
  }) : assert(quietZone >= 0, 'quietZone must be >= 0');

  /// Default style of dark modules.
  final QrModuleStyle moduleStyle;

  /// Optional per-module override, called once per dark module per paint.
  final QrModuleStyleBuilder? moduleBuilder;

  /// Fill behind the code, including the quiet zone. Use a transparent color
  /// for no background.
  final Color backgroundColor;

  /// Light margin around the symbol, in modules. The QR specification
  /// requires 4; smaller values may fail on some scanners.
  final int quietZone;

  /// Resolves the style for [module].
  QrModuleStyle styleFor(QrModuleContext module) =>
      moduleBuilder?.call(module) ?? moduleStyle;

  /// Returns a copy with the given fields replaced.
  QrDesign copyWith({
    QrModuleStyle? moduleStyle,
    QrModuleStyleBuilder? moduleBuilder,
    Color? backgroundColor,
    int? quietZone,
  }) {
    return QrDesign(
      moduleStyle: moduleStyle ?? this.moduleStyle,
      moduleBuilder: moduleBuilder ?? this.moduleBuilder,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      quietZone: quietZone ?? this.quietZone,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QrDesign &&
      other.moduleStyle == moduleStyle &&
      other.moduleBuilder == moduleBuilder &&
      other.backgroundColor == backgroundColor &&
      other.quietZone == quietZone;

  @override
  int get hashCode =>
      Object.hash(moduleStyle, moduleBuilder, backgroundColor, quietZone);
}
