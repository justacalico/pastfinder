import 'package:flutter_test/flutter_test.dart';
import 'package:pastfinder/scanner/scanner_service.dart';

import 'fakes.dart';

void main() {
  test('scan collects new pastes and fetches bodies', () async {
    final store = await makeStore();
    final source = FakeSource(
      items: [makePaste(id: '1'), makePaste(id: '2')],
      content: 'body',
    );
    final scanner =
        ScannerService(sources: [source], store: store);
    final report = await scanner.scan();
    expect(report.newCount, 2);
    expect(report.errors, isEmpty);
    expect(store.pastes.every((p) => p.content == 'body'), isTrue);

    // Second scan finds nothing new.
    final again = await scanner.scan();
    expect(again.newCount, 0);
  });

  test('disabled sources are skipped', () async {
    final store = await makeStore();
    final on = FakeSource(sourceId: 'fake', items: [makePaste(id: '1')]);
    final off = FakeSource(
        sourceId: 'off', items: [makePaste(id: '9', source: 'off')]);
    store.setEnabled('off', false);
    final scanner = ScannerService(sources: [on, off], store: store);
    final report = await scanner.scan();
    expect(report.newCount, 1);
    expect(store.pastes.single.source, 'fake');
  });

  test('source errors are reported, other sources continue', () async {
    final store = await makeStore();
    final broken =
        FakeSource(sourceId: 'bad', sourceName: 'Bad', error: 'boom');
    final good = FakeSource(sourceId: 'ok', items: [makePaste(id: '1')]);
    final scanner = ScannerService(sources: [broken, good], store: store);
    final report = await scanner.scan();
    expect(report.errors, hasLength(1));
    expect(report.errors.single, contains('Bad'));
    expect(report.newCount, 1);
  });

  test('content errors are swallowed', () async {
    final store = await makeStore();
    final source = FakeSource(
      items: [makePaste(id: '1')],
      contentError: Exception('nope'),
    );
    final scanner = ScannerService(sources: [source], store: store);
    final report = await scanner.scan();
    expect(report.newCount, 1);
    expect(store.pastes.single.content, isNull);
  });

  test('fetchBodies false leaves content null', () async {
    final store = await makeStore();
    final source =
        FakeSource(items: [makePaste(id: '1')], content: 'body');
    final scanner = ScannerService(
        sources: [source], store: store, fetchBodies: false);
    await scanner.scan();
    expect(store.pastes.single.content, isNull);
  });
}
