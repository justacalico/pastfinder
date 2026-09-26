import '../models/paste.dart';
import '../sources/paste_source.dart';
import '../storage/paste_store.dart';

class ScanReport {
  ScanReport({required this.newPastes, required this.errors});

  /// Newly stored pastes.
  final List<Paste> newPastes;

  /// Per-source failures as "source: message" strings.
  final List<String> errors;

  int get newCount => newPastes.length;
}

/// Walks the enabled sources, pulls their latest public pastes, and stores
/// whatever is new.
class ScannerService {
  ScannerService({
    required this.sources,
    required this.store,
    this.fetchBodies = true,
  });

  final List<PasteSource> sources;
  final PasteStore store;

  /// Whether to grab paste bodies right away or leave them for the detail
  /// view. Bodies make scans slower but the library searchable.
  final bool fetchBodies;

  Future<ScanReport> scan() async {
    final newPastes = <Paste>[];
    final errors = <String>[];

    for (final source in sources) {
      if (!store.isEnabled(source.id)) continue;
      List<Paste> latest;
      try {
        latest = await source.fetchLatest();
      } catch (error) {
        errors.add('${source.name}: $error');
        continue;
      }
      final known = store.knownIds;
      final fresh =
          latest.where((p) => !known.contains(p.key)).toList(growable: false);
      if (fetchBodies) {
        for (final paste in fresh) {
          try {
            paste.content = await source.fetchContent(paste);
          } catch (_) {
            // Leave content null; it can be fetched on demand later.
          }
        }
      }
      store.addAll(fresh);
      newPastes.addAll(fresh);
    }

    return ScanReport(newPastes: newPastes, errors: errors);
  }
}
