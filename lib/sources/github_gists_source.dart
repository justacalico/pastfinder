import 'dart:convert';



import '../models/paste.dart';
import 'paste_source.dart';

/// GitHub gists public timeline.
class GithubGistsSource extends PasteSource {
  GithubGistsSource({super.client});

  static const _endpoint = 'https://api.github.com/gists/public?per_page=30';

  @override
  String get id => 'github_gists';

  @override
  String get name => 'GitHub Gists';

  @override
  String get homeUrl => 'https://gist.github.com';

  @override
  String get description => 'Public gist timeline from api.github.com';

  @override
  Future<List<Paste>> fetchLatest() async {
    final response = await client.get(
      Uri.parse(_endpoint),
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'pastfinder',
      },
    );
    if (response.statusCode != 200) {
      throw StateError('GitHub API returned ${response.statusCode}');
    }
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final files = (item['files'] as Map<String, dynamic>? ?? {})
              .values
              .whereType<Map<String, dynamic>>()
              .toList();
          final owner = item['owner'] as Map<String, dynamic>?;
          final description = (item['description'] as String? ?? '').trim();
          final firstFile = files.isEmpty ? null : files.first;
          final filename = firstFile?['filename'] as String? ?? '';
          return Paste(
            source: id,
            id: item['id'] as String? ?? '',
            title: description.isNotEmpty
                ? description
                : (filename.isNotEmpty ? filename : 'Untitled gist'),
            author: owner?['login'] as String? ?? '',
            url: item['html_url'] as String? ?? '',
            rawUrl: firstFile?['raw_url'] as String?,
            createdAt: DateTime.tryParse(item['created_at'] as String? ?? ''),
            fetchedAt: DateTime.now(),
          );
        })
        .where((paste) => paste.id.isNotEmpty)
        .toList();
  }
}
