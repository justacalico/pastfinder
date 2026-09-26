import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/paste.dart';

class PasteDetailPage extends StatefulWidget {
  const PasteDetailPage({
    super.key,
    required this.paste,
    required this.sourceName,
    this.fetchContent,
    this.onContentLoaded,
  });

  final Paste paste;
  final String sourceName;
  final Future<String?> Function(Paste)? fetchContent;
  final void Function(String content)? onContentLoaded;

  @override
  State<PasteDetailPage> createState() => _PasteDetailPageState();
}

class _PasteDetailPageState extends State<PasteDetailPage> {
  bool _loading = false;
  String? _error;

  Future<void> _loadContent() async {
    final fetch = widget.fetchContent;
    if (fetch == null) {
      setState(() => _error = 'This source has no content endpoint.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final content = await fetch(widget.paste);
      if (!mounted) return;
      if (content == null) {
        setState(() {
          _loading = false;
          _error = 'Could not fetch content.';
        });
      } else {
        widget.paste.content = content;
        widget.onContentLoaded?.call(content);
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paste = widget.paste;
    return Scaffold(
      appBar: AppBar(
        title: Text(paste.title),
        actions: [
          if (paste.hasContent)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy content',
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: paste.content!),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(widget.sourceName)),
              if (paste.author.isNotEmpty)
                Chip(label: Text(paste.author)),
              if (paste.createdAt != null)
                Chip(label: Text(paste.createdAt!.toLocal().toString())),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            paste.url,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(height: 32),
          if (paste.hasContent)
            SelectableText(
              paste.content!,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            )
          else if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton.icon(
              onPressed: _loadContent,
              icon: const Icon(Icons.cloud_download),
              label: const Text('Load content'),
            ),
          ],
        ],
      ),
    );
  }
}
