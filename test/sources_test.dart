import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pastfinder/models/paste.dart';
import 'package:pastfinder/sources/github_gists_source.dart';
import 'package:pastfinder/sources/gitlab_snippets_source.dart';
import 'package:pastfinder/sources/glot_source.dart';
import 'package:pastfinder/sources/paste_source.dart';
import 'package:pastfinder/sources/pastebin_archive_source.dart';
import 'package:pastfinder/sources/sources.dart';

Paste barePaste({String? rawUrl}) => Paste(
      source: 'x',
      id: '1',
      title: 't',
      url: 'u',
      rawUrl: rawUrl,
      fetchedAt: DateTime(2026),
    );

void main() {
  test('defaultSources registers all sources', () {
    final sources = defaultSources();
    expect(sources.map((s) => s.id), [
      'github_gists',
      'gitlab_snippets',
      'glot',
      'pastebin_archive',
    ]);
    for (final s in sources) {
      expect(s.name, isNotEmpty);
      expect(s.homeUrl, startsWith('https://'));
      expect(s.description, isNotEmpty);
    }
  });

  group('PasteSource.fetchContent default', () {
    PasteSource source(http.Client client) =>
        _StubSource(client: client);

    test('returns null without rawUrl', () async {
      final s = source(MockClient((r) async => http.Response('', 200)));
      expect(await s.fetchContent(barePaste()), isNull);
    });

    test('returns body on 200', () async {
      final s = source(
          MockClient((r) async => http.Response('paste body', 200)));
      expect(await s.fetchContent(barePaste(rawUrl: 'https://x/raw')),
          'paste body');
    });

    test('returns null on failure status', () async {
      final s =
          source(MockClient((r) async => http.Response('nope', 404)));
      expect(await s.fetchContent(barePaste(rawUrl: 'https://x/raw')),
          isNull);
    });
  });

  group('GithubGistsSource', () {
    test('parses the public timeline', () async {
      final client = MockClient((r) async {
        expect(r.url.toString(), contains('api.github.com/gists/public'));
        expect(r.headers['User-Agent'], 'pastfinder');
        return http.Response('''[
          {"id": "g1", "description": "config dump", "html_url": "https://g/g1",
           "created_at": "2026-01-02T03:04:05Z",
           "owner": {"login": "alice"},
           "files": {"main.py": {"filename": "main.py", "raw_url": "https://raw/g1"}}},
          {"id": "g2", "description": "", "html_url": "https://g/g2",
           "owner": null, "files": {"a.txt": {"filename": "a.txt"}}},
          {"id": "g3", "description": null, "files": {}},
          {"id": "", "files": {}},
          "not a map"
        ]''', 200);
      });
      final pastes = await GithubGistsSource(client: client).fetchLatest();
      expect(pastes, hasLength(3));
      expect(pastes[0].id, 'g1');
      expect(pastes[0].title, 'config dump');
      expect(pastes[0].author, 'alice');
      expect(pastes[0].rawUrl, 'https://raw/g1');
      expect(pastes[0].createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
      expect(pastes[1].title, 'a.txt');
      expect(pastes[2].title, 'Untitled gist');
    });

    test('throws on non-200', () {
      final client = MockClient((r) async => http.Response('', 403));
      expect(GithubGistsSource(client: client).fetchLatest(),
          throwsStateError);
    });
  });

  group('GitlabSnippetsSource', () {
    test('parses public snippets', () async {
      final client = MockClient((r) async => http.Response('''[
        {"id": 7, "title": "deploy.sh", "web_url": "https://gl/7",
         "raw_url": "https://gl/7/raw", "created_at": "2026-02-01T00:00:00Z",
         "author": {"username": "bob"}},
        {"id": 8, "title": "  ", "author": null},
        {"title": "no id"},
        "junk"
      ]''', 200));
      final pastes =
          await GitlabSnippetsSource(client: client).fetchLatest();
      expect(pastes, hasLength(2));
      expect(pastes[0].id, '7');
      expect(pastes[0].title, 'deploy.sh');
      expect(pastes[0].author, 'bob');
      expect(pastes[0].rawUrl, 'https://gl/7/raw');
      expect(pastes[1].title, 'Untitled snippet');
    });

    test('throws on non-200', () {
      final client = MockClient((r) async => http.Response('', 500));
      expect(GitlabSnippetsSource(client: client).fetchLatest(),
          throwsStateError);
    });
  });

  group('GlotSource', () {
    test('parses public snippet list', () async {
      final client = MockClient((r) async => http.Response('''[
        {"id": "abc", "title": "fizzbuzz", "language": "python",
         "owner": "carol", "created": "2026-01-01T00:00:00Z"},
        {"id": "def", "title": "", "language": "rust",
         "created_at": "2026-01-02T00:00:00Z"},
        {"id": "ghi", "title": " "},
        {"title": "no id"},
        42
      ]''', 200));
      final pastes = await GlotSource(client: client).fetchLatest();
      expect(pastes, hasLength(3));
      expect(pastes[0].id, 'abc');
      expect(pastes[0].title, 'fizzbuzz');
      expect(pastes[0].author, 'carol');
      expect(pastes[0].url, 'https://glot.io/snippets/abc');
      expect(pastes[0].createdAt, DateTime.utc(2026));
      expect(pastes[1].title, 'rust snippet');
      expect(pastes[1].createdAt, DateTime.utc(2026, 1, 2));
      expect(pastes[2].title, 'Snippet');
    });

    test('fetchContent concatenates files', () async {
      final client = MockClient((r) async {
        expect(r.url.toString(), 'https://glot.io/api/snippets/1');
        return http.Response(
            '{"files": [{"name": "a.py", "content": "one"}, {"content": "two"}]}',
            200);
      });
      final body =
          await GlotSource(client: client).fetchContent(barePaste());
      expect(body, contains('# a.py'));
      expect(body, contains('one'));
      expect(body, contains('two'));
    });

    test('fetchContent returns null on failure', () async {
      final client = MockClient((r) async => http.Response('', 404));
      expect(await GlotSource(client: client).fetchContent(barePaste()),
          isNull);
    });

    test('throws on non-200 list', () {
      final client = MockClient((r) async => http.Response('', 500));
      expect(GlotSource(client: client).fetchLatest(), throwsStateError);
    });
  });

  group('PastebinArchiveSource', () {
    test('parses archive entries and dedupes ids', () async {
      final client = MockClient((r) async => http.Response('''
        <a class="i_0" href="/AbCdEf12">first paste</a>
        <a href="/XyZ12345">second &amp; paste</a>
        <a href="/AbCdEf12">duplicate</a>
      ''', 200));
      final pastes =
          await PastebinArchiveSource(client: client).fetchLatest();
      expect(pastes, hasLength(2));
      expect(pastes[0].id, 'AbCdEf12');
      expect(pastes[0].title, 'first paste');
      expect(pastes[0].url, 'https://pastebin.com/AbCdEf12');
      expect(pastes[0].rawUrl, 'https://pastebin.com/raw/AbCdEf12');
    });

    test('throws on non-200', () {
      final client = MockClient((r) async => http.Response('denied', 403));
      expect(PastebinArchiveSource(client: client).fetchLatest(),
          throwsStateError);
    });

    test('throws when the page has no entries', () {
      final client =
          MockClient((r) async => http.Response('<html></html>', 200));
      expect(PastebinArchiveSource(client: client).fetchLatest(),
          throwsStateError);
    });
  });
}

class _StubSource extends PasteSource {
  _StubSource({super.client});

  @override
  String get id => 'stub';

  @override
  String get name => 'Stub';

  @override
  String get homeUrl => '';

  @override
  String get description => '';

  @override
  Future<List<Paste>> fetchLatest() async => const [];
}
