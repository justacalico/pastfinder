import 'package:pastfinder/models/paste.dart';
import 'package:pastfinder/sources/paste_source.dart';
import 'package:pastfinder/storage/paste_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSource extends PasteSource {
  FakeSource({
    this.sourceId = 'fake',
    this.sourceName = 'Fake Source',
    this.items = const [],
    this.error,
    this.content,
    this.contentError,
  });

  final String sourceId;
  final String sourceName;
  final List<Paste> items;
  final Object? error;
  final String? content;
  final Object? contentError;

  @override
  String get id => sourceId;

  @override
  String get name => sourceName;

  @override
  String get homeUrl => 'https://example.com';

  @override
  String get description => 'fake';

  @override
  Future<List<Paste>> fetchLatest() async {
    if (error != null) throw error!;
    return items;
  }

  @override
  Future<String?> fetchContent(Paste paste) async {
    if (contentError != null) throw contentError!;
    return content;
  }
}

Paste makePaste({
  String source = 'fake',
  String id = '1',
  String title = 'Test paste',
  String author = 'alice',
  String? content,
  DateTime? createdAt,
}) {
  return Paste(
    source: source,
    id: id,
    title: title,
    author: author,
    url: 'https://example.com/$id',
    rawUrl: 'https://example.com/$id/raw',
    createdAt: createdAt,
    fetchedAt: DateTime(2026, 1, 1),
    content: content,
  );
}

Future<PasteStore> makeStore() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return PasteStore(prefs)..load();
}
