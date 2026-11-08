import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/editor_tab.dart';
import '../theme/vscode_theme.dart';

class EditorProvider extends ChangeNotifier {
  final List<EditorTab> _tabs = [];
  String? _activeTabId;
  final int _errorCount = 0;
  final int _warningCount = 0;

  List<EditorTab> get tabs => List.unmodifiable(_tabs);

  EditorTab? get activeTab {
    if (_activeTabId == null) return null;
    try {
      return _tabs.firstWhere((t) => t.id == _activeTabId);
    } catch (_) {
      return null;
    }
  }

  String? get activeTabId => _activeTabId;
  int get errorCount => _errorCount;
  int get warningCount => _warningCount;

  Future<void> openFile(String filePath) async {
    // Check if already open
    final existing = _tabs.where((t) => t.path == filePath).toList();
    if (existing.isNotEmpty) {
      _activeTabId = existing.first.id;
      notifyListeners();
      return;
    }

    try {
      final file = File(filePath);
      String content = '';
      if (await file.exists()) {
        content = await file.readAsString();
      }

      final filename = filePath.split('/').last;
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final language = VSCodeTheme.languageFromExtension(filename);

      final tab = EditorTab(
        id: id,
        path: filePath,
        filename: filename,
        content: content,
        language: language,
      );

      _tabs.add(tab);
      _activeTabId = id;
      notifyListeners();
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  void setActiveTab(String tabId) {
    _activeTabId = tabId;
    notifyListeners();
  }

  void closeTab(String tabId) {
    final idx = _tabs.indexWhere((t) => t.id == tabId);
    if (idx == -1) return;

    _tabs.removeAt(idx);

    if (_activeTabId == tabId) {
      if (_tabs.isEmpty) {
        _activeTabId = null;
      } else if (idx < _tabs.length) {
        _activeTabId = _tabs[idx].id;
      } else {
        _activeTabId = _tabs[_tabs.length - 1].id;
      }
    }

    notifyListeners();
  }

  void updateContent(String tabId, String content) {
    final idx = _tabs.indexWhere((t) => t.id == tabId);
    if (idx == -1) return;

    _tabs[idx] = _tabs[idx].copyWith(
      content: content,
      isModified: true,
    );
    notifyListeners();
  }

  Future<void> saveTab(String tabId) async {
    final tab = _tabs.firstWhere((t) => t.id == tabId, orElse: () => throw Exception('Tab not found'));

    try {
      final file = File(tab.path);
      await file.writeAsString(tab.content);

      final idx = _tabs.indexWhere((t) => t.id == tabId);
      _tabs[idx] = _tabs[idx].copyWith(isModified: false);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving file: $e');
    }
  }

  Future<void> saveActiveTab() async {
    if (_activeTabId != null) {
      await saveTab(_activeTabId!);
    }
  }

  void updateCursor(String tabId, int line, int column) {
    final idx = _tabs.indexWhere((t) => t.id == tabId);
    if (idx == -1) return;

    _tabs[idx] = _tabs[idx].copyWith(
      cursorLine: line,
      cursorColumn: column,
    );
    notifyListeners();
  }

  void newUntitledFile() {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final filename = 'Untitled-${_tabs.length + 1}';
    final tab = EditorTab(
      id: id,
      path: '/tmp/$filename',
      filename: filename,
      content: '',
      language: 'plaintext',
      isModified: true,
    );
    _tabs.add(tab);
    _activeTabId = id;
    notifyListeners();
  }
}
