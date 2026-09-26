

import '../models/paste.dart';
import 'paste_source.dart';

/// Scrapes the public archive listing on pastebin.com.
///
/// This is best effort: pastebin.com sits behind Cloudflare and blocks some
/// clients. Failures surface as scan errors and do not break other sources.
class PastebinArchiveSource extends PasteSource {
  PastebinArchiveSource({super.client});

  static const _archiveUrl = 'https://pastebin.com/archive';

  @override
  String get id => 'pastebin_archive';

  @override
  String get name => 'Pastebin';

  @override
  String get homeUrl => 'https://pastebin.com/archive';

  @override
  String get description => 'Public archive on pastebin.com (best effort)';

  static final _entryPattern =
      RegExp(r'href="/([A-Za-z0-9]{8})"[^>]*>([^<]+)</a>');

  @override
  Future<List<Paste>> fetchLatest() async {
    final response = await client.get(
      Uri.parse(_archiveUrl),
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
      },
    );
    if (response.statusCode != 200) {
      throw StateError('pastebin.com returned ${response.statusCode}');
    }
    final seen = <String>{};
    final pastes = <Paste>[];
    for (final match in _entryPattern.allMatches(response.body)) {
      final pasteId = match.group(1)!;
      if (!seen.add(pasteId)) continue;
      pastes.add(
        Paste(
          source: id,
          id: pasteId,
          title: match.group(2)!.trim(),
          url: 'https://pastebin.com/$pasteId',
          rawUrl: 'https://pastebin.com/raw/$pasteId',
          fetchedAt: DateTime.now(),
        ),
      );
    }
    if (pastes.isEmpty) {
      throw StateError('No archive entries found (likely blocked)');
    }
    return pastes;
  }
}
