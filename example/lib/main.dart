import 'package:flutter/material.dart';

import 'pages/designer_page.dart';
import 'pages/gallery_page.dart';
import 'pages/scanner_page.dart';

void main() => runApp(const FlexiQrExampleApp());

class FlexiQrExampleApp extends StatelessWidget {
  const FlexiQrExampleApp({super.key, this.scannerBuilder});

  /// Builds the scanner tab; replaceable so tests can avoid the camera.
  final WidgetBuilder? scannerBuilder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flexi_qr_kit',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF3949AB)),
      home: HomePage(scannerBuilder: scannerBuilder),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.scannerBuilder});

  final WidgetBuilder? scannerBuilder;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  static const _titles = ['Gallery', 'Designer', 'Scanner'];

  @override
  Widget build(BuildContext context) {
    final body = switch (_tab) {
      0 => const GalleryPage(),
      1 => const DesignerPage(),
      _ => widget.scannerBuilder?.call(context) ?? const ScannerPage(),
    };
    return Scaffold(
      appBar: AppBar(title: Text('flexi_qr_kit · ${_titles[_tab]}')),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Designer',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scanner',
          ),
        ],
      ),
    );
  }
}
