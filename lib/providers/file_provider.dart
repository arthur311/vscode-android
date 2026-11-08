import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/file_node.dart';
import '../services/prefs_service.dart';

const _kLastDirKey = 'last_opened_directory';

class FileProvider extends ChangeNotifier {
  List<FileNode> _fileTree = [];
  String? _rootPath;
  bool _isLoading = false;

  /// Set when openDirectory or pickAndOpenDirectory fails. Triggers the
  /// full-screen error banner. Cleared at the start of every openDirectory.
  String? _rootError;

  /// Set when a file operation (create/delete) fails. Consumed once by the
  /// UI as a SnackBar so it never hides the file tree. Cleared after read.
  String? _opError;

  List<FileNode> get fileTree => _fileTree;
  String? get rootPath => _rootPath;
  bool get isLoading => _isLoading;
  String? get rootError => _rootError;

  /// Returns the pending operation error and clears it so the UI shows it
  /// exactly once (consume-once pattern).
  String? consumeOpError() {
    final e = _opError;
    _opError = null;
    return e;
  }

  String get rootName {
    if (_rootPath == null) return 'No folder opened';
    return _rootPath!.split('/').last.toUpperCase();
  }

  FileProvider() {
    _restoreLastDirectory();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _restoreLastDirectory() async {
    await PrefsService.instance.load();
    final saved = PrefsService.instance.getString(_kLastDirKey);
    if (saved != null && await Directory(saved).exists()) {
      await openDirectory(saved);
    } else {
      final fallback = await getApplicationDocumentsDirectory();
      await openDirectory(fallback.path);
    }
  }

  Future<void> _saveLastDirectory(String path) async {
    await PrefsService.instance.setString(_kLastDirKey, path);
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Opens the OS folder-picker dialog (SAF on Android 11+).
  /// Returns true if the user picked a directory, false if they cancelled.
  ///
  /// SAF restrictions on Android 11+ (OS, not our code):
  ///   - /storage/emulated/0 root cannot be picked directly.
  ///   - Downloads/ is blocked on many OEMs (Samsung, Xiaomi).
  ///   - Any sub-folder of those locations can be picked.
  Future<bool> pickAndOpenDirectory() async {
    try {
      final picked = await getDirectoryPath();
      if (picked == null) return false;
      await openDirectory(picked);
      return true;
    } catch (e) {
      _rootError = 'Could not open folder picker: ${_friendlyError(e)}';
      notifyListeners();
      return false;
    }
  }

  Future<void> openDirectory(String path) async {
    _isLoading = true;
    _rootError = null;
    notifyListeners();

    try {
      _rootPath = path;
      _fileTree = await _buildFileTree(path);
      await _saveLastDirectory(path);
    } catch (e) {
      _rootError = _friendlyError(e);
      _fileTree = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshTree() async {
    if (_rootPath != null) await openDirectory(_rootPath!);
  }

  Future<void> toggleDirectory(FileNode node) async {
    if (!node.isDirectory) return;
    if (node.isExpanded) {
      node.isExpanded = false;
      node.listError = null;
    } else {
      node.isExpanded = true;
      if (node.children.isEmpty && node.listError == null) {
        try {
          node.children = await _buildFileTree(node.path);
        } catch (e) {
          node.listError = _friendlyError(e);
          node.children = [];
        }
      }
    }
    notifyListeners();
  }

  /// File operations use _opError (SnackBar) not _rootError (banner),
  /// so a failed create/delete never hides the existing file tree.
  Future<void> createFile(String dirPath, String fileName) async {
    try {
      await File('$dirPath/$fileName').create(recursive: true);
      await refreshTree();
    } catch (e) {
      _opError = 'Cannot create file "$fileName": ${_friendlyError(e)}';
      notifyListeners();
    }
  }

  Future<void> createFolder(String dirPath, String folderName) async {
    try {
      await Directory('$dirPath/$folderName').create(recursive: true);
      await refreshTree();
    } catch (e) {
      _opError = 'Cannot create folder "$folderName": ${_friendlyError(e)}';
      notifyListeners();
    }
  }

  Future<void> deleteNode(FileNode node) async {
    try {
      if (node.isDirectory) {
        await Directory(node.path).delete(recursive: true);
      } else {
        await File(node.path).delete();
      }
      await refreshTree();
    } catch (e) {
      _opError = 'Cannot delete "${node.name}": ${_friendlyError(e)}';
      notifyListeners();
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Converts an exception to a short user-readable message.
  /// Checks [FileSystemException.osError?.errorCode] first (POSIX codes),
  /// falls back to a generic message rather than leaking raw exception text.
  String _friendlyError(Object e) {
    if (e is FileSystemException) {
      final code = e.osError?.errorCode;
      if (code == 13) return 'Permission denied — grant "All files access" in Settings';
      if (code == 2)  return 'File or folder no longer exists';
      if (code == 17) return 'File already exists';
      if (code == 28) return 'No space left on device';
      // Known non-POSIX message from _buildFileTree when dir.exists() is false
      if (e.message.contains('does not exist')) return 'Folder no longer exists';
    }
    // Do not expose raw stack or internal paths to the user.
    return 'Unexpected error (${e.runtimeType})';
  }

  /// Throws [FileSystemException] when listing fails so callers decide how to
  /// surface the error. Never swallows exceptions silently.
  Future<List<FileNode>> _buildFileTree(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      throw FileSystemException('Directory does not exist', dirPath);
    }

    final entities = await dir.list(followLinks: false).toList();

    entities.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      if (aIsDir && !bIsDir) return -1;
      if (!aIsDir && bIsDir) return 1;
      return a.path.split('/').last.compareTo(b.path.split('/').last);
    });

    final List<FileNode> nodes = [];
    for (final entity in entities) {
      final name = entity.path.split('/').last;
      if (name.startsWith('.') ||
          name == 'node_modules' ||
          name == '__pycache__' ||
          name == 'build') {
        continue;
      }
      nodes.add(FileNode(
        name: name,
        path: entity.path,
        isDirectory: entity is Directory,
      ));
    }
    return nodes;
  }
}
