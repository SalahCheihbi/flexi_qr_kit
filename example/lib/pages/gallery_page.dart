import 'package:flexi_qr_kit/flexi_qr_kit.dart';
import 'package:flutter/material.dart';

import '../showcases.dart';
import '../widgets/export_dialog.dart';
import '../widgets/validation_panel.dart';

/// Grid of every showcase, grouped by category.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = <String, List<Showcase>>{};
    for (final showcase in showcases) {
      (categories[showcase.category] ??= []).add(showcase);
    }

    return CustomScrollView(
      slivers: [
        for (final MapEntry(key: category, value: items) in categories.entries)
          SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    category,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.8,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => ShowcaseCard(showcase: items[i]),
                ),
              ),
            ],
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

/// Builds the code of [showcase], with an error message when it cannot be
/// encoded.
Widget showcaseQr(Showcase showcase, {double? size}) => FlexiQrGenerator(
  data: showcase.data,
  design: showcase.design,
  errorCorrectionLevel: showcase.errorCorrectionLevel,
  size: size,
  errorBuilder: (context, error) => ColoredBox(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          error is FlexiQrException ? error.message : '$error',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    ),
  ),
);

class ShowcaseCard extends StatelessWidget {
  const ShowcaseCard({super.key, required this.showcase});

  final Showcase showcase;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('card-${showcase.slug}'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ShowcasePage(showcase: showcase),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: showcaseQr(showcase),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                showcase.title,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One showcase at full size, with its validation report and PNG export.
class ShowcasePage extends StatelessWidget {
  const ShowcasePage({super.key, required this.showcase});

  final Showcase showcase;

  @override
  Widget build(BuildContext context) {
    final canExport = showcase.outcome != ShowcaseOutcome.encodingError;
    return Scaffold(
      appBar: AppBar(
        title: Text(showcase.title),
        actions: [
          if (canExport)
            IconButton(
              tooltip: 'Export PNG',
              icon: const Icon(Icons.download),
              onPressed: () => showExportDialog(
                context,
                data: showcase.data,
                design: showcase.design,
                errorCorrectionLevel: showcase.errorCorrectionLevel,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: showcaseQr(showcase, size: 300)),
          const SizedBox(height: 16),
          Text(showcase.description),
          const SizedBox(height: 8),
          ValidationPanel(
            data: showcase.data,
            design: showcase.design,
            errorCorrectionLevel: showcase.errorCorrectionLevel,
          ),
        ],
      ),
    );
  }
}
