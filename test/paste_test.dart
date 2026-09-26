import 'package:flutter_test/flutter_test.dart';
import 'package:pastfinder/models/paste.dart';

void main() {
  test('key combines source and id', () {
    final paste = Paste(
      source: 's',
      id: '42',
      title: 't',
      url: 'u',
      fetchedAt: DateTime(2026),
    );
    expect(paste.key, 's:42');
    expect(paste.hasContent, isFalse);
    paste.content = 'body';
    expect(paste.hasContent, isTrue);
  });

  test('json roundtrip keeps all fields', () {
    final paste = Paste(
      source: 'gist',
      id: 'abc',
      title: 'Hello',
      author: 'bob',
      url: 'https://x/abc',
      rawUrl: 'https://x/abc/raw',
      createdAt: DateTime(2026, 3, 5),
      fetchedAt: DateTime(2026, 3, 6),
      content: 'print(1)',
    );
    final restored = Paste.fromJson(paste.toJson());
    expect(restored.source, 'gist');
    expect(restored.id, 'abc');
    expect(restored.title, 'Hello');
    expect(restored.author, 'bob');
    expect(restored.url, 'https://x/abc');
    expect(restored.rawUrl, 'https://x/abc/raw');
    expect(restored.createdAt, DateTime(2026, 3, 5));
    expect(restored.fetchedAt, DateTime(2026, 3, 6));
    expect(restored.content, 'print(1)');
  });

  test('fromJson tolerates missing fields', () {
    final paste = Paste.fromJson(const {});
    expect(paste.source, '');
    expect(paste.id, '');
    expect(paste.author, '');
    expect(paste.rawUrl, isNull);
    expect(paste.createdAt, isNull);
    expect(paste.content, isNull);
  });

  test('toJson handles null createdAt', () {
    final paste = Paste(
      source: 's',
      id: 'i',
      title: 't',
      url: 'u',
      fetchedAt: DateTime(2026),
    );
    expect(paste.toJson()['createdAt'], isNull);
  });
}
