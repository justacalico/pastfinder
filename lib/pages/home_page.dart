import 'package:flutter/material.dart';

import '../scanner/scanner_service.dart';
import '../storage/paste_store.dart';
import 'pastes_page.dart';
import 'scanner_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.store, required this.scanner});

  final PasteStore store;
  final ScannerService scanner;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ScannerPage(store: widget.store, scanner: widget.scanner),
      PastesPage(store: widget.store, scanner: widget.scanner),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.radar),
            label: 'Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}
