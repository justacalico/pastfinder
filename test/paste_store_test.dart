import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pastfinder/storage/paste_store.dart';

import 'fakes.dart';

void main() {
  test('addAll dedupes and prepends', () async {
    final store = await makeStore();
    expect(store.addAll([makePaste(id: '1'), makePaste(id: '2')]), 2);
    expect(store.addAll([makePaste(id: '2'), makePaste(id: '3')]), 1);
    expect(store.pastes.map((p) => p.id), ['3', '1', '2']);
  });

  test('caps the library at maxPastes', () async {
    final store = await makeStore();
    final batch = List.generate(
      PasteStore.maxPastes + 5,
      (i) => makePaste(id: '$i'),
    );
    store.addAll(batch);
    expect(store.pastes.length, PasteStore.maxPastes);
  });

  test('persists and reloads pastes', () async {
    final store = await makeStore();
    store.addAll([makePaste(id: '1', content: 'body')]);
    // A second store over the same prefs sees the saved data.
    final prefs = await SharedPreferences.getInstance();
    final reloaded = PasteStore(prefs)..load();
    expect(reloaded.pastes, hasLength(1));
    expect(reloaded.pastes.single.content, 'body');
  });

  test('load with no data stays empty', () async {
    final store = await makeStore();
    expect(store.pastes, isEmpty);
    expect(store.knownIds, isEmpty);
  });

  test('updateContent sets body on matching key only', () async {
    final store = await makeStore();
    store.addAll([makePaste(id: '1'), makePaste(id: '2')]);
    store.updateContent('fake:1', 'hello');
    expect(store.pastes[0].id, '1');
    expect(store.pastes[0].content, 'hello');
    store.updateContent('fake:nope', 'x');
    expect(store.pastes[1].content, isNull);
    expect(store.pastes[0].content, 'hello');
  });

  test('sources enabled by default, disable keeps others on', () async {
    final store = await makeStore();
    expect(store.isEnabled('a'), isTrue);
    store.setEnabled('b', false);
    expect(store.isEnabled('a'), isTrue);
    expect(store.isEnabled('b'), isFalse);
    store.setEnabled('b', true);
    expect(store.isEnabled('b'), isTrue);
  });

  test('enabled set survives reload', () async {
    final store = await makeStore();
    store.setEnabled('a', false);
    final prefs = await SharedPreferences.getInstance();
    final reloaded = PasteStore(prefs)..load();
    expect(reloaded.isEnabled('a'), isFalse);
    expect(reloaded.isEnabled('b'), isTrue);
  });

  test('clear wipes stored pastes', () async {
    final store = await makeStore();
    store.addAll([makePaste(id: '1')]);
    await store.clear();
    expect(store.pastes, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    final reloaded = PasteStore(prefs)..load();
    expect(reloaded.pastes, isEmpty);
  });
}
