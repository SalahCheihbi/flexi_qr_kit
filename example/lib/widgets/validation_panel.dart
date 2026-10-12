import 'dart:async';

import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/material.dart';

/// Validates a design with [QrValidator] and lists the result.
///
/// Validation runs again, debounced, whenever [data] or [design] change.
class ValidationPanel extends StatefulWidget {
  const ValidationPanel({
    super.key,
    required this.data,
    required this.design,
    this.errorCorrectionLevel,
    this.size = 300,
    this.debounce = const Duration(milliseconds: 300),
  });

  final String data;
  final QrDesign design;
  final QrErrorCorrectionLevel? errorCorrectionLevel;
  final double size;
  final Duration debounce;

  @override
  State<ValidationPanel> createState() => _ValidationPanelState();
}

class _ValidationPanelState extends State<ValidationPanel> {
  Timer? _timer;
  QrValidationResult? _result;
  Object? _error;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _validate();
  }

  @override
  void didUpdateWidget(ValidationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.design != widget.design ||
        oldWidget.errorCorrectionLevel != widget.errorCorrectionLevel ||
        oldWidget.size != widget.size) {
      _timer?.cancel();
      _timer = Timer(widget.debounce, _validate);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _validate() async {
    final run = ++_run;
    setState(() {
      _result = null;
      _error = null;
    });
    try {
      final logo = widget.design.logo;
      final result = await const QrValidator().validate(
        widget.data,
        design: widget.design,
        errorCorrectionLevel: widget.errorCorrectionLevel,
        size: widget.size,
        logoImage: logo == null ? null : await resolveQrLogoImage(logo.image),
      );
      if (mounted && run == _run) setState(() => _result = result);
    } catch (e) {
      if (mounted && run == _run) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    final result = _result;

    if (error != null) {
      return _StatusTile(
        icon: Icons.error,
        color: theme.colorScheme.error,
        title: 'Cannot encode',
        subtitle: error is FlexiQrException ? error.message : '$error',
      );
    }
    if (result == null) {
      return const ListTile(
        leading: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Validating…'),
      );
    }

    final (icon, color, title) = switch (result.status) {
      QrValidationStatus.valid => (
        Icons.verified,
        Colors.green.shade700,
        'Valid: decodes as expected',
      ),
      QrValidationStatus.warning => (
        Icons.warning_amber,
        Colors.orange.shade800,
        'Usable, with warnings',
      ),
      QrValidationStatus.invalid => (
        Icons.cancel,
        theme.colorScheme.error,
        'Invalid',
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusTile(
          icon: icon,
          color: color,
          title: title,
          subtitle: result.decodedText == null
              ? null
              : 'Decoded: ${result.decodedText}',
        ),
        for (final issue in result.issues)
          ListTile(
            dense: true,
            leading: Icon(
              issue.severity == QrIssueSeverity.error
                  ? Icons.close
                  : Icons.info_outline,
              size: 18,
            ),
            title: Text(issue.message),
            subtitle: Text(issue.code.name),
          ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
