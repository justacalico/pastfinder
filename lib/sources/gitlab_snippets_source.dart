import 'dart:convert';



import '../models/paste.dart';
import 'paste_source.dart';

/// Public snippets on gitlab.com.
class GitlabSnippetsSource extends PasteSource {
  GitlabSnippetsSource({super.client});

  static const _endpoint =
      'https://gitlab.com/api/v4/snippets/public?per_page=20';

  @override
  String get id => 'gitlab_snippets';

  @override
  String get name => 'GitLab Snippets';

  @override
  String get homeUrl => 'https://gitlab.com/explore/snippets';

  @override
  String get description => 'Public snippets from gitlab.com';

  @override
  Future<List<Paste>> fetchLatest() async {
    final response = await client.get(
      Uri.parse(_endpoint),
      headers: const {'User-Agent': 'pastfinder'},
    );
    if (response.statusCode != 200) {
      throw StateError('GitLab API returned ${response.statusCode}');
    }
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final author = item['author'] as Map<String, dynamic>?;
          final title = (item['title'] as String? ?? '').trim();
          return Paste(
            source: id,
            id: '${item['id']}',
            title: title.isNotEmpty ? title : 'Untitled snippet',
            author: author?['username'] as String? ?? '',
            url: item['web_url'] as String? ?? '',
            rawUrl: item['raw_url'] as String?,
            createdAt: DateTime.tryParse(item['created_at'] as String? ?? ''),
            fetchedAt: DateTime.now(),
          );
        })
        .where((paste) => paste.id.isNotEmpty && paste.id != 'null')
        .toList();
  }
}
