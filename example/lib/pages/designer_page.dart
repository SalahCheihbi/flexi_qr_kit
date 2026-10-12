import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/material.dart';

import '../designer_config.dart';
import '../widgets/export_dialog.dart';
import '../widgets/validation_panel.dart';

/// Live editor: every control rebuilds the preview and revalidates it.
class DesignerPage extends StatefulWidget {
  const DesignerPage({super.key, this.initial = const DesignerConfig()});

  final DesignerConfig initial;

  @override
  State<DesignerPage> createState() => _DesignerPageState();
}

class _DesignerPageState extends State<DesignerPage> {
  late DesignerConfig _config = widget.initial;
  late final _dataController = TextEditingController(text: _config.data);

  void _update(DesignerConfig config) => setState(() => _config = config);

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final design = _config.toDesign();
    final preview = Column(
      children: [
        FlexiQrGenerator(
          key: const Key('designer-preview'),
          data: _config.data,
          design: design,
          errorCorrectionLevel: _config.errorCorrectionLevel,
          size: 280,
          errorBuilder: (context, error) => const SizedBox.square(
            dimension: 280,
            child: Center(child: Text('Cannot encode this payload')),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const Key('designer-export'),
          onPressed: () => showExportDialog(
            context,
            data: _config.data,
            design: design,
            errorCorrectionLevel: _config.errorCorrectionLevel,
          ),
          icon: const Icon(Icons.download),
          label: const Text('Export PNG'),
        ),
        ValidationPanel(
          data: _config.data,
          design: design,
          errorCorrectionLevel: _config.errorCorrectionLevel,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 840) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: preview,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: ListView(children: _controls())),
            ],
          );
        }
        return ListView(
          children: [
            Padding(padding: const EdgeInsets.all(16), child: preview),
            const Divider(),
            ..._controls(),
          ],
        );
      },
    );
  }

  List<Widget> _controls() {
    final c = _config;
    return [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          key: const Key('designer-data'),
          controller: _dataController,
          decoration: const InputDecoration(
            labelText: 'Payload',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _update(c.copyWith(data: value)),
        ),
      ),
      _Section(
        title: 'Module shape',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final shape in QrModuleShape.values)
              ChoiceChip(
                key: Key('shape-${shape.name}'),
                label: Text(shape.name),
                selected: c.shape == shape,
                onSelected: (_) => _update(c.copyWith(shape: shape)),
              ),
          ],
        ),
      ),
      _Section(
        title: 'Corner mode',
        child: SegmentedButton<QrCornerMode>(
          key: const Key('corner-mode'),
          segments: const [
            ButtonSegment(value: QrCornerMode.manual, label: Text('Manual')),
            ButtonSegment(value: QrCornerMode.smart, label: Text('Smart')),
          ],
          selected: {c.cornerMode},
          onSelectionChanged: (s) => _update(c.copyWith(cornerMode: s.single)),
        ),
      ),
      _Section(
        title: 'Corner radii (px)',
        child: Column(
          children: [
            _SliderRow(
              id: 'radius-topLeft',
              label: 'Top left',
              value: c.topLeft,
              max: 12,
              onChanged: (v) => _update(c.copyWith(topLeft: v)),
            ),
            _SliderRow(
              id: 'radius-topRight',
              label: 'Top right',
              value: c.topRight,
              max: 12,
              onChanged: (v) => _update(c.copyWith(topRight: v)),
            ),
            _SliderRow(
              id: 'radius-bottomRight',
              label: 'Bottom right',
              value: c.bottomRight,
              max: 12,
              onChanged: (v) => _update(c.copyWith(bottomRight: v)),
            ),
            _SliderRow(
              id: 'radius-bottomLeft',
              label: 'Bottom left',
              value: c.bottomLeft,
              max: 12,
              onChanged: (v) => _update(c.copyWith(bottomLeft: v)),
            ),
          ],
        ),
      ),
      _Section(
        title: 'Size',
        child: Column(
          children: [
            _SliderRow(
              id: 'scale',
              label: 'Scale',
              value: c.scale,
              min: 0.5,
              max: 1,
              onChanged: (v) => _update(c.copyWith(scale: v)),
            ),
            _SliderRow(
              id: 'spacing',
              label: 'Spacing',
              value: c.spacing,
              max: 3,
              onChanged: (v) => _update(c.copyWith(spacing: v)),
            ),
            _SliderRow(
              id: 'quiet-zone',
              label: 'Quiet zone',
              value: c.quietZone.toDouble(),
              max: 8,
              divisions: 8,
              onChanged: (v) => _update(c.copyWith(quietZone: v.round())),
            ),
          ],
        ),
      ),
      _Section(
        title: 'Color',
        child: Row(
          children: [
            for (final (i, color) in DesignerConfig.palette.indexed)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  key: Key('color-$i'),
                  customBorder: const CircleBorder(),
                  onTap: () => _update(c.copyWith(color: color)),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: color,
                    child: c.color == color
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
      SwitchListTile(
        key: const Key('gradient'),
        title: const Text('Gradient'),
        value: c.gradient,
        onChanged: (v) => _update(c.copyWith(gradient: v)),
      ),
      _Section(
        title: 'Finder patterns',
        child: SegmentedButton<FinderPreset>(
          key: const Key('finder'),
          segments: [
            for (final preset in FinderPreset.values)
              ButtonSegment(value: preset, label: Text(preset.name)),
          ],
          selected: {c.finder},
          onSelectionChanged: (s) => _update(c.copyWith(finder: s.single)),
        ),
      ),
      SwitchListTile(
        key: const Key('logo'),
        title: const Text('Center logo'),
        subtitle: const Text('Error correction switches to H on Auto'),
        value: c.logo,
        onChanged: (v) => _update(c.copyWith(logo: v)),
      ),
      _Section(
        title: 'Error correction',
        child: SegmentedButton<QrErrorCorrectionLevel?>(
          key: const Key('ecl'),
          segments: const [
            ButtonSegment(value: null, label: Text('Auto')),
            ButtonSegment(value: QrErrorCorrectionLevel.low, label: Text('L')),
            ButtonSegment(
              value: QrErrorCorrectionLevel.medium,
              label: Text('M'),
            ),
            ButtonSegment(
              value: QrErrorCorrectionLevel.quartile,
              label: Text('Q'),
            ),
            ButtonSegment(value: QrErrorCorrectionLevel.high, label: Text('H')),
          ],
          selected: {c.errorCorrectionLevel},
          onSelectionChanged: (s) => _update(
            c.copyWith(
              errorCorrectionLevel: s.single,
              autoErrorCorrection: s.single == null,
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.id,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    required this.max,
    this.divisions,
  });

  final String id;
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 96, child: Text(label)),
        Expanded(
          child: Slider(
            key: Key(id),
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(value.toStringAsFixed(divisions == null ? 1 : 0)),
        ),
      ],
    );
  }
}
