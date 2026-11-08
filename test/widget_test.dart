// Smoke test untuk VSCodeAndroidApp.
//
// VSCodeAndroidApp memanggil FileProvider saat init, yang langsung memanggil
// path_provider dan file I/O. Di test environment (tanpa platform plugin),
// ini melempar MissingPluginException saat pumpWidget.
//
// Strategi: uji komponen yang bisa berdiri sendiri tanpa platform channel.
// Test integrasi penuh (dengan path_provider mock) masuk Fase 4.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vscode_android/theme/vscode_theme.dart';
import 'package:vscode_android/models/editor_tab.dart';
import 'package:vscode_android/models/file_node.dart';

void main() {
  group('VSCodeTheme', () {
    test('languageFromExtension dart', () {
      expect(VSCodeTheme.languageFromExtension('main.dart'), 'dart');
    });

    test('languageFromExtension unknown falls back to plaintext', () {
      expect(VSCodeTheme.languageFromExtension('file.xyz'), 'plaintext');
    });

    test('languageFromExtension no extension falls back to plaintext', () {
      expect(VSCodeTheme.languageFromExtension('Makefile'), 'plaintext');
    });
  });

  group('EditorTab', () {
    test('copyWith preserves unchanged fields', () {
      final tab = EditorTab(
        id: '1',
        path: '/tmp/foo.dart',
        filename: 'foo.dart',
        content: 'void main() {}',
        language: 'dart',
      );
      final modified = tab.copyWith(isModified: true);
      expect(modified.id, '1');
      expect(modified.path, '/tmp/foo.dart');
      expect(modified.isModified, true);
      expect(modified.content, 'void main() {}');
    });

    test('initial isModified is false', () {
      final tab = EditorTab(
        id: '2',
        path: '/tmp/bar.js',
        filename: 'bar.js',
        content: '',
        language: 'javascript',
      );
      expect(tab.isModified, false);
    });
  });

  group('FileNode', () {
    test('isDirectory flag', () {
      final dir = FileNode(name: 'src', path: '/src', isDirectory: true);
      final file = FileNode(name: 'main.dart', path: '/src/main.dart', isDirectory: false);
      expect(dir.isDirectory, true);
      expect(file.isDirectory, false);
    });

    test('listError starts null', () {
      final node = FileNode(name: 'lib', path: '/lib', isDirectory: true);
      expect(node.listError, isNull);
    });

    test('equality by path', () {
      final a = FileNode(name: 'a', path: '/lib', isDirectory: true);
      final b = FileNode(name: 'b', path: '/lib', isDirectory: false);
      expect(a, equals(b)); // same path → equal regardless of name
    });
  });

  group('VSCodeTheme colors', () {
    test('background is dark', () {
      // #1e1e1e = 0xFF1E1E1E
      expect(VSCodeTheme.background, const Color(0xFF1E1E1E));
    });

    test('accentBlue matches VS Code', () {
      expect(VSCodeTheme.accentBlue, const Color(0xFF007ACC));
    });
  });
}
