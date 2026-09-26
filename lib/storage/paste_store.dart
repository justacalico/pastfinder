import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/paste.dart';

/// Persists collected pastes and per-source enablement locally.
class PasteStore extends ChangeNotifier {
  PasteStore(this._prefs);

  static const _pastesKey = 'pastes_v1';
  static const _disabledKey = 'disabled_sources_v1';
  static const maxPastes = 2000;

  final SharedPreferences _prefs;
  List<Paste> _pastes = const [];
  Set<String> _disabled = const {};

  List<Paste> get pastes => List.unmodifiable(_pastes);

  Set<String> get knownIds => _pastes.map((p) => p.key).toSet();

  bool isEnabled(String sourceId) => !_disabled.contains(sourceId);

  void setEnabled(String sourceId, bool enabled) {
    _disabled = enabled
        ? ({..._disabled}..remove(sourceId))
        : ({..._disabled}..add(sourceId));
    _saveDisabled();
    notifyListeners();
  }

  /// Inserts [incoming] skipping pastes already stored. Returns how many
  /// were actually new.
  int addAll(Iterable<Paste> incoming) {
    final known = knownIds;
    final fresh =
        incoming.where((p) => !known.contains(p.key)).toList(growable: false);
    if (fresh.isEmpty) return 0;
    _pastes = [...fresh, ..._pastes];
    if (_pastes.length > maxPastes) {
      _pastes = _pastes.sublist(0, maxPastes);
    }
    _save();
    notifyListeners();
    return fresh.length;
  }

  void updateContent(String key, String content) {
    for (final paste in _pastes) {
      if (paste.key == key) {
        paste.content = content;
        _save();
        notifyListeners();
        return;
      }
    }
  }

  Future<void> clear() async {
    _pastes = const [];
    await _prefs.remove(_pastesKey);
    notifyListeners();
  }

  void load() {
    final raw = _prefs.getString(_pastesKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _pastes = decoded
          .whereType<Map<String, dynamic>>()
          .map(Paste.fromJson)
          .toList();
    }
    _disabled = (_prefs.getStringList(_disabledKey) ?? const []).toSet();
    notifyListeners();
  }

  void _save() {
    _prefs.setString(
      _pastesKey,
      jsonEncode(_pastes.map((p) => p.toJson()).toList()),
    );
  }

  void _saveDisabled() {
    _prefs.setStringList(_disabledKey, _disabled.toList());
  }
}
