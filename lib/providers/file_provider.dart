import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/file_node.dart';

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
    _loadDefaultPath();
  }

  Future<void> _loadDefaultPath() async {
    try {
      Directory? dir;
      if (Platform.isAndroid) {
        final extDirs = await getExternalStorageDirectories();
        if (extDirs != null && extDirs.isNotEmpty) {
          dir = extDirs.first;
        } else {
          dir = await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (await dir.exists()) {
        await openDirectory(dir.path);
      }
    } catch (e) {
      debugPrint('Error loading default path: $e');
    }
  }

  Future<void> pickAndOpenDirectory() async {
    // Without file_picker we open the app documents directory or prompt
    try {
      await openDefaultDirectory();
    } catch (e) {
      _errorMessage = 'Error picking directory: $e';
      notifyListeners();
    }
  }

  Future<void> openDirectory(String path) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _rootPath = path;
      _fileTree = await _buildFileTree(path);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error opening directory: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<FileNode>> _buildFileTree(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final List<FileNode> nodes = [];

    try {
      final entities = await dir.list(followLinks: false).toList();

      entities.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return a.path.split('/').last.compareTo(b.path.split('/').last);
      });

      for (final entity in entities) {
        final name = entity.path.split('/').last;

        // Skip hidden files/folders and common ignore patterns
        if (name.startsWith('.') ||
            name == 'node_modules' ||
            name == '__pycache__' ||
            name == 'build') {
          continue;
        }

        if (entity is Directory) {
          nodes.add(FileNode(
            name: name,
            path: entity.path,
            isDirectory: true,
          ));
        } else if (entity is File) {
          nodes.add(FileNode(
            name: name,
            path: entity.path,
            isDirectory: false,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error listing directory $dirPath: $e');
    }

    return nodes;
  }

  Future<void> toggleDirectory(FileNode node) async {
    if (!node.isDirectory) return;

    if (node.isExpanded) {
      node.isExpanded = false;
    } else {
      node.isExpanded = true;
      if (node.children.isEmpty) {
        node.children = await _buildFileTree(node.path);
      }
    }
    notifyListeners();
  }

  Future<void> refreshTree() async {
    if (_rootPath != null) {
      await openDirectory(_rootPath!);
    }
  }

  Future<void> openDefaultDirectory() async {
    try {
      Directory? dir;
      if (Platform.isAndroid) {
        // Try public storage first
        final extDir = Directory('/storage/emulated/0');
        if (await extDir.exists()) {
          dir = extDir;
        } else {
          final extDirs = await getExternalStorageDirectories();
          if (extDirs != null && extDirs.isNotEmpty) {
            dir = extDirs.first;
          }
        }
      }
      dir ??= await getApplicationDocumentsDirectory();

      if (await dir.exists()) {
        await openDirectory(dir.path);
      }
    } catch (e) {
      debugPrint('Error opening default directory: $e');
    }
  }

  Future<void> createFile(String dirPath, String fileName) async {
    try {
      final file = File('$dirPath/$fileName');
      await file.create(recursive: true);
      await refreshTree();
    } catch (e) {
      _errorMessage = 'Error creating file: $e';
      notifyListeners();
    }
  }

  Future<void> createFolder(String dirPath, String folderName) async {
    try {
      final dir = Directory('$dirPath/$folderName');
      await dir.create(recursive: true);
      await refreshTree();
    } catch (e) {
      _errorMessage = 'Error creating folder: $e';
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
      _errorMessage = 'Error deleting: $e';
      notifyListeners();
    }
  }
}
