import 'dart:convert';



import '../models/paste.dart';
import 'paste_source.dart';

/// Public snippets on glot.io.
class GlotSource extends PasteSource {
  GlotSource({super.client});

  static const _listEndpoint = 'https://glot.io/api/snippets';
  static const _snippetEndpoint = 'https://glot.io/api/snippets/';

  @override
  String get id => 'glot';

  @override
  String get name => 'glot.io';

  @override
  String get homeUrl => 'https://glot.io';

  @override
  String get description => 'Public code snippets from glot.io';

  @override
  Future<List<Paste>> fetchLatest() async {
    final response = await client.get(
      Uri.parse(_listEndpoint),
      headers: const {'User-Agent': 'pastfinder'},
    );
    if (response.statusCode != 200) {
      throw StateError('glot.io API returned ${response.statusCode}');
    }
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final title = (item['title'] as String? ?? '').trim();
          final snippetId = '${item['id'] ?? ''}';
          final language = item['language'] as String? ?? '';
          return Paste(
            source: id,
            id: snippetId,
            title: title.isNotEmpty
                ? title
                : (language.isNotEmpty ? '$language snippet' : 'Snippet'),
            author: item['owner'] as String? ?? '',
            url: 'https://glot.io/snippets/$snippetId',
            createdAt:
                DateTime.tryParse(item['created'] as String? ?? '') ??
                    DateTime.tryParse(item['created_at'] as String? ?? ''),
            fetchedAt: DateTime.now(),
          );
        })
        .where((paste) => paste.id.isNotEmpty)
        .toList();
  }

  @override
  Future<String?> fetchContent(Paste paste) async {
    final response = await client.get(
      Uri.parse('$_snippetEndpoint${paste.id}'),
      headers: const {'User-Agent': 'pastfinder'},
    );
    if (response.statusCode != 200) return null;
    final item = jsonDecode(response.body) as Map<String, dynamic>;
    final files = (item['files'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>();
    final buffer = StringBuffer();
    for (final file in files) {
      final name = file['name'] as String? ?? '';
      final content = file['content'] as String? ?? '';
      if (name.isNotEmpty) buffer.writeln('# $name');
      buffer.writeln(content);
    }
    return buffer.toString().trim();
  }
}
