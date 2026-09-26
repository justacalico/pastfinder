import 'package:http/http.dart' as http;

import '../models/paste.dart';

/// A paste service that exposes some way to list public pastes.
abstract class PasteSource {
  PasteSource({http.Client? client}) : client = client ?? http.Client();

  final http.Client client;

  /// Stable identifier used for storage and settings.
  String get id;

  /// Human readable name.
  String get name;

  /// Homepage of the service.
  String get homeUrl;

  /// Short note shown in the UI about what is scanned.
  String get description;

  /// Returns metadata for the latest public pastes.
  ///
  /// Implementations should throw on failure; the scanner records the error
  /// and moves on to the next source.
  Future<List<Paste>> fetchLatest();

  /// Returns the raw body of [paste], or null when the source has no raw
  /// endpoint or the fetch failed.
  Future<String?> fetchContent(Paste paste) async {
    final raw = paste.rawUrl;
    if (raw == null) return null;
    final response = await client.get(Uri.parse(raw));
    if (response.statusCode != 200) return null;
    return response.body;
  }
}
