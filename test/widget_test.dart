import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pastfinder/app.dart';
import 'package:pastfinder/main.dart' as app;
import 'package:pastfinder/pages/paste_detail_page.dart';
import 'package:pastfinder/scanner/scanner_service.dart';
import 'package:pastfinder/storage/paste_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  Future<(PasteStore, ScannerService)> harness({
    List<FakeSource>? sources,
  }) async {
    final store = await makeStore();
    final srcs = sources ??
        [
          FakeSource(
              items: [makePaste(id: 'n1', title: 'Fresh paste')],
              content: 'the body'),
        ];
    final scanner = ScannerService(sources: srcs, store: store);
    return (store, scanner);
  }

  testWidgets('main() boots the real app', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await app.main();
    await tester.pump();
    expect(find.text('Scanner'), findsWidgets);
  });

  testWidgets('scanner tab lists sources and runs a scan', (tester) async {
    final (store, scanner) = await harness(sources: [
      FakeSource(
          items: [makePaste(id: 'x1', title: 'p1')], content: 'c'),
      FakeSource(sourceId: 'bad', sourceName: 'Bad', error: 'denied'),
    ]);
    await tester.pumpWidget(PastfinderApp(store: store, scanner: scanner));
    await tester.pumpAndSettle();

    expect(find.text('Fake Source'), findsOneWidget);
    expect(find.text('Bad'), findsOneWidget);

    await tester.tap(find.text('Scan now'));
    await tester.pumpAndSettle();

    expect(find.text('Found 1 new paste(s).'), findsOneWidget);
    expect(find.textContaining('Bad'), findsWidgets);
    expect(store.pastes, hasLength(1));
  });

  testWidgets('empty scan reports no new pastes', (tester) async {
    final (store, scanner) =
        await harness(sources: [FakeSource()]);
    await tester.pumpWidget(PastfinderApp(store: store, scanner: scanner));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan now'));
    await tester.pumpAndSettle();
    expect(find.text('No new pastes found.'), findsOneWidget);
  });

  testWidgets('source toggle disables scanning for it', (tester) async {
    final (store, scanner) = await harness(sources: [
      FakeSource(items: [makePaste(id: 'x1')]),
    ]);
    await tester.pumpWidget(PastfinderApp(store: store, scanner: scanner));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(store.isEnabled('fake'), isFalse);

    await tester.tap(find.text('Scan now'));
    await tester.pumpAndSettle();
    expect(find.text('No new pastes found.'), findsOneWidget);
    expect(store.pastes, isEmpty);
  });

  testWidgets('library shows pastes, search filters, detail opens',
      (tester) async {
    final (store, scanner) = await harness();
    store.addAll([
      makePaste(
          id: 'a',
          title: 'Password dump',
          content: 'secret',
          createdAt: DateTime(2026, 1, 5)),
      makePaste(id: 'b', title: 'cookie recipe'),
    ]);
    await tester.pumpWidget(PastfinderApp(store: store, scanner: scanner));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Password dump'), findsOneWidget);
    expect(find.text('cookie recipe'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'password');
    await tester.pumpAndSettle();
    expect(find.text('Password dump'), findsOneWidget);
    expect(find.text('cookie recipe'), findsNothing);

    await tester.tap(find.text('Password dump'));
    await tester.pumpAndSettle();
    expect(find.text('secret'), findsOneWidget);
    expect(find.text('Fake Source'), findsWidgets);

    // Copy button.
    await tester.tap(find.byIcon(Icons.copy));
    await tester.pumpAndSettle();
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('detail page loads content on demand', (tester) async {
    final (store, scanner) = await harness();
    store.addAll(
        [makePaste(id: 'lazy', createdAt: DateTime(2026, 2, 2))]);
    await tester.pumpWidget(PastfinderApp(store: store, scanner: scanner));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test paste'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Load content'));
    await tester.pumpAndSettle();
    expect(find.text('the body'), findsOneWidget);
    expect(store.pastes.single.content, 'the body');
  });

  testWidgets('detail page shows spinner while fetching', (tester) async {
    final completer = Completer<String?>();
    await tester.pumpWidget(MaterialApp(
      home: PasteDetailPage(
        paste: makePaste(id: 'slow', createdAt: DateTime(2026, 3, 3)),
        sourceName: 'Fake',
        fetchContent: (_) => completer.future,
      ),
    ));
    await tester.tap(find.text('Load content'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete('done');
    await tester.pumpAndSettle();
    expect(find.text('done'), findsOneWidget);
  });

  testWidgets('detail page shows fetch error', (tester) async {
    final (store, scanner) = await harness(sources: [
      FakeSource(contentError: Exception('timeout')),
    ]);
    store.addAll([makePaste(id: 'lazy')]);
    await tester.pumpWidget(PastfinderApp(store: store, scanner: scanner));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test paste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load content'));
    await tester.pumpAndSettle();
    expect(find.textContaining('timeout'), findsOneWidget);
  });

  testWidgets('detail page handles null content and missing fetcher',
      (tester) async {
    final paste = makePaste(id: 'p', content: null);
    // fetchContent returns null.
    await tester.pumpWidget(MaterialApp(
      home: PasteDetailPage(
        paste: paste,
        sourceName: 'Fake',
        fetchContent: (p) async => null,
      ),
    ));
    await tester.tap(find.text('Load content'));
    await tester.pumpAndSettle();
    expect(find.text('Could not fetch content.'), findsOneWidget);

    // No fetcher at all.
    await tester.pumpWidget(MaterialApp(
      home: PasteDetailPage(paste: makePaste(id: 'q'), sourceName: 'Fake'),
    ));
    await tester.tap(find.text('Load content'));
    await tester.pumpAndSettle();
    expect(find.text('This source has no content endpoint.'),
        findsOneWidget);
  });

  testWidgets('clear library deletes all pastes', (tester) async {
    final (store, scanner) = await harness();
    store.addAll([makePaste(id: 'a')]);
    await tester.pumpWidget(PastfinderApp(store: store, scanner: scanner));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_sweep));
    await tester.pumpAndSettle();
    expect(find.text('Clear library?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.pastes, hasLength(1));

    await tester.tap(find.byIcon(Icons.delete_sweep));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(store.pastes, isEmpty);
  });
}
