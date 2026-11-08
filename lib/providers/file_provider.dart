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
  String? _errorMessage;

  List<FileNode> get fileTree => _fileTree;
  String? get rootPath => _rootPath;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
      // Fall back to app documents dir so explorer is not empty on first run
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
  Future<bool> pickAndOpenDirectory() async {
    try {
      // getDirectoryPath() triggers the SAF directory picker on Android.
      // On Android 11+ the user CANNOT pick:
      //   - The storage root (/storage/emulated/0) directly
      //   - The Download folder directly (OS restriction, not our bug)
      // They can pick any sub-folder of those locations.
      final picked = await getDirectoryPath();
      if (picked == null) return false; // user cancelled

      await openDirectory(picked);
      return true;
    } catch (e) {
      _errorMessage = 'Could not open folder picker: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> openDirectory(String path) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rootPath = path;
      _fileTree = await _buildFileTree(path);
      await _saveLastDirectory(path);
    } catch (e) {
      _errorMessage = _friendlyError(e);
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
          // Surface the error on the node so the UI can show it inline.
          node.listError = _friendlyError(e);
          node.children = [];
        }
      }
    }
    notifyListeners();
  }

  /// Converts a raw exception into a short, user-readable message.
  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Permission denied') || msg.contains('EACCES')) {
      return 'Permission denied — grant "All files access" in Settings';
    }
    if (msg.contains('does not exist') || msg.contains('ENOENT')) {
      return 'Folder no longer exists';
    }
    return 'Cannot read folder: $msg';
  }

  Future<void> createFile(String dirPath, String fileName) async {
    try {
      await File('$dirPath/$fileName').create(recursive: true);
      await refreshTree();
    } catch (e) {
      _errorMessage = 'Cannot create file: $e';
      notifyListeners();
    }
  }

  Future<void> createFolder(String dirPath, String folderName) async {
    try {
      await Directory('$dirPath/$folderName').create(recursive: true);
      await refreshTree();
    } catch (e) {
      _errorMessage = 'Cannot create folder: $e';
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
      _errorMessage = 'Cannot delete: $e';
      notifyListeners();
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Throws [FileSystemException] if the directory cannot be listed (e.g.
  /// permission denied). Callers that want partial results (subfolder expand)
  /// catch and store the error on the node; callers that open a root directory
  /// let it bubble up to [openDirectory] which surfaces it via [_errorMessage].
  Future<List<FileNode>> _buildFileTree(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      throw FileSystemException('Directory does not exist', dirPath);
    }

    // Let this throw — do NOT catch here so callers can decide how to surface it.
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
