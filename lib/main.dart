import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'scanner/scanner_service.dart';
import 'sources/sources.dart';
import 'storage/paste_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = PasteStore(prefs)..load();
  final sources = defaultSources();
  final scanner = ScannerService(sources: sources, store: store);
  runApp(PastfinderApp(store: store, scanner: scanner));
}
