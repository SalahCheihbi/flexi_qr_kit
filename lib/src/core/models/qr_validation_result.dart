import 'package:flutter/foundation.dart';

/// Overall outcome of a validation.
enum QrValidationStatus {
  /// No issues found and the rendered code decoded correctly.
  valid,

  /// The code decoded, but some settings carry a readability risk.
  warning,

  /// The code failed to decode, decoded to different content, or uses a
  /// configuration that is known to break scanning.
  invalid,
}

/// How serious a [QrValidationIssue] is.
enum QrIssueSeverity {
  /// A readability risk. The code may still scan on many devices.
  warning,

  /// A failure. The code should not be published as is.
  error,
}

/// What a [QrValidationIssue] is about.
enum QrIssueCode {
  /// The rendered image could not be decoded.
  decodeFailed,

  /// The rendered image decoded to different content than the input.
  contentMismatch,

  /// Quiet zone smaller than the 4 modules required by the specification.
  quietZoneTooSmall,

  /// Not enough contrast between dark modules and the background.
  lowContrast,

  /// Modules lighter than the background. Many scanners cannot read
  /// inverted codes.
  invertedColors,

  /// The logo hides too much of the encoded data for the error correction
  /// level.
  logoTooLarge,

  /// Modules are rendered with too few pixels.
  moduleTooSmall,

  /// The background is transparent, so contrast depends on what is behind
  /// the image.
  transparentBackground,

  /// A finder uses geometry outside the scanner-safe range.
  unsafeFinderGeometry,

  /// Modules are scaled down a lot, leaving little dark area per module.
  smallModuleScale,

  /// Modules are rotated, which reduces their coverage of the grid cell.
  rotatedModules,
}

/// A single finding of the validator.
@immutable
class QrValidationIssue {
  /// Creates an issue.
  const QrValidationIssue(this.code, this.severity, this.message);

  /// What the issue is about.
  final QrIssueCode code;

  /// How serious it is.
  final QrIssueSeverity severity;

  /// Human-readable explanation, suitable for display.
  final String message;

  @override
  bool operator ==(Object other) =>
      other is QrValidationIssue &&
      other.code == code &&
      other.severity == severity &&
      other.message == message;

  @override
  int get hashCode => Object.hash(code, severity, message);

  @override
  String toString() => '${severity.name}: $message';
}

/// Result of validating a styled QR code.
///
/// Automated decoding uses a single decoder on a perfect digital image. A
/// [QrValidationStatus.valid] result is strong evidence, not a guarantee:
/// always test important codes on real Android and iOS devices, printed
/// and on screen.
@immutable
class QrValidationResult {
  /// Builds a result from [issues]. The status is derived from the most
  /// severe issue.
  QrValidationResult({
    required Iterable<QrValidationIssue> issues,
    this.decodedText,
  }) : issues = List.unmodifiable(issues);

  /// All findings, in the order they were detected.
  final List<QrValidationIssue> issues;

  /// Text decoded from the rendered image, or null when decoding failed or
  /// was skipped.
  final String? decodedText;

  /// Overall outcome.
  QrValidationStatus get status {
    if (issues.any((i) => i.severity == QrIssueSeverity.error)) {
      return QrValidationStatus.invalid;
    }
    return issues.isEmpty
        ? QrValidationStatus.valid
        : QrValidationStatus.warning;
  }

  /// Whether the code may be used: valid or warning.
  bool get isUsable => status != QrValidationStatus.invalid;

  /// Issues of [QrIssueSeverity.error].
  Iterable<QrValidationIssue> get errors =>
      issues.where((i) => i.severity == QrIssueSeverity.error);

  /// Issues of [QrIssueSeverity.warning].
  Iterable<QrValidationIssue> get warnings =>
      issues.where((i) => i.severity == QrIssueSeverity.warning);

  /// Whether any issue has [code].
  bool has(QrIssueCode code) => issues.any((i) => i.code == code);

  @override
  String toString() =>
      'QrValidationResult(${status.name}, ${issues.length} issue(s))';
}

/// How strictly validation gates export.
enum QrValidationMode {
  /// Refuse to export codes whose validation is
  /// [QrValidationStatus.invalid].
  strict,

  /// Always export, and report every risk in the result. Use it to
  /// experiment.
  advanced,
}
