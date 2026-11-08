import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Persistent key-value store backed by a JSON file in the app's documents
/// directory. Used instead of shared_preferences because that package requires
/// flutter_web_plugins which is absent from this Flutter installation.
class PrefsService {
  static PrefsService? _instance;
  static PrefsService get instance => _instance ??= PrefsService._();
  PrefsService._();

  Map<String, dynamic> _cache = {};
  bool _loaded = false;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/app_prefs.json');
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final f = await _file();
      if (await f.exists()) {
        final raw = await f.readAsString();
        _cache = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      }
    } catch (_) {
      _cache = {};
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(_cache));
    } catch (_) {}
  }

  String? getString(String key) => _cache[key] as String?;

  Future<void> setString(String key, String value) async {
    _cache[key] = value;
    await _persist();
  }

  Future<void> remove(String key) async {
    _cache.remove(key);
    await _persist();
  }
}
