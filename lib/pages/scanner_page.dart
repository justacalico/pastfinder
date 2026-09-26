import 'package:flutter/material.dart';

import '../scanner/scanner_service.dart';
import '../storage/paste_store.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, required this.store, required this.scanner});

  final PasteStore store;
  final ScannerService scanner;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool _scanning = false;
  ScanReport? _lastReport;
  DateTime? _lastScanAt;

  Future<void> _runScan() async {
    setState(() => _scanning = true);
    final report = await widget.scanner.scan();
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _lastReport = report;
      _lastScanAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sources = widget.scanner.sources;
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final source in sources)
            SwitchListTile(
              title: Text(source.name),
              subtitle: Text(source.description),
              secondary: const Icon(Icons.public),
              value: widget.store.isEnabled(source.id),
              onChanged: _scanning
                  ? null
                  : (v) => widget.store.setEnabled(source.id, v),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _scanning ? null : _runScan,
            icon: _scanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_scanning ? 'Scanning…' : 'Scan now'),
          ),
          const SizedBox(height: 16),
          if (_lastReport != null) ...[
            Text(
              _lastReport!.newCount == 0
                  ? 'No new pastes found.'
                  : 'Found ${_lastReport!.newCount} new paste(s).',
            ),
            if (_lastScanAt != null)
              Text(
                'Last scan ${_lastScanAt!.toLocal()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            for (final error in _lastReport!.errors)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  error,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ] else
            Text(
              '${widget.store.pastes.length} paste(s) in library.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
