import 'package:flutter/material.dart';

import '../models/paste.dart';
import '../scanner/scanner_service.dart';
import '../storage/paste_store.dart';
import 'paste_detail_page.dart';

class PastesPage extends StatefulWidget {
  const PastesPage({super.key, required this.store, required this.scanner});

  final PasteStore store;
  final ScannerService scanner;

  @override
  State<PastesPage> createState() => _PastesPageState();
}

class _PastesPageState extends State<PastesPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    _searchController.addListener(
      () => setState(() => _query = _searchController.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  bool _matches(Paste paste) {
    if (_query.isEmpty) return true;
    return paste.title.toLowerCase().contains(_query) ||
        paste.author.toLowerCase().contains(_query) ||
        (paste.content ?? '').toLowerCase().contains(_query);
  }

  String _sourceName(String sourceId) {
    for (final source in widget.scanner.sources) {
      if (source.id == sourceId) return source.name;
    }
    return sourceId;
  }

  Future<void> _clearLibrary() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear library?'),
        content: const Text('All saved pastes will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm == true) await widget.store.clear();
  }

  @override
  Widget build(BuildContext context) {
    final pastes = widget.store.pastes.where(_matches).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear library',
            onPressed: pastes.isEmpty ? null : _clearLibrary,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search title, author or content',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: pastes.isEmpty
                ? const Center(child: Text('No pastes yet. Run a scan.'))
                : ListView.separated(
                    itemCount: pastes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final paste = pastes[i];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(_sourceName(paste.source)[0]),
                        ),
                        title: Text(
                          paste.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [
                            _sourceName(paste.source),
                            if (paste.author.isNotEmpty) paste.author,
                            if (paste.createdAt != null)
                              paste.createdAt!.toLocal().toString(),
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: paste.hasContent
                            ? const Icon(Icons.description)
                            : const Icon(Icons.cloud_download_outlined),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => PasteDetailPage(
                              paste: paste,
                              sourceName: _sourceName(paste.source),
                              fetchContent: widget.scanner.sources
                                  .where((s) => s.id == paste.source)
                                  .firstOrNull
                                  ?.fetchContent,
                              onContentLoaded: (content) => widget.store
                                  .updateContent(paste.key, content),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
