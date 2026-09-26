import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'scanner/scanner_service.dart';
import 'storage/paste_store.dart';

class PastfinderApp extends StatelessWidget {
  const PastfinderApp({
    super.key,
    required this.store,
    required this.scanner,
  });

  final PasteStore store;
  final ScannerService scanner;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pastfinder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomePage(store: store, scanner: scanner),
    );
  }
}
