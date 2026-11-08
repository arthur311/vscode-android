import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/vscode_theme.dart';
import '../providers/editor_provider.dart';

class StatusBar extends StatefulWidget {
  const StatusBar({super.key});

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  String _gitBranch = '';

  @override
  void initState() {
    super.initState();
    _loadGitBranch();
  }

  Future<void> _loadGitBranch() async {
    try {
      final result = await Process.run(
        'git',
        ['branch', '--show-current'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final branch = result.stdout.toString().trim();
        if (branch.isNotEmpty) {
          setState(() => _gitBranch = branch);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, editorProvider, _) {
        final activeTab = editorProvider.activeTab;

        return Container(
          height: 22,
          color: VSCodeTheme.statusBar,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // Left: git branch
              if (_gitBranch.isNotEmpty) ...[
                const Icon(Icons.call_split, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  _gitBranch,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Error/warning counts
              if (editorProvider.errorCount > 0) ...[
                const Icon(Icons.error_outline, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '${editorProvider.errorCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                const SizedBox(width: 8),
              ],
              if (editorProvider.warningCount > 0) ...[
                const Icon(Icons.warning_amber_outlined, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '${editorProvider.warningCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],

              const Spacer(),

              // Right: file info
              if (activeTab != null) ...[
                Text(
                  'Ln ${activeTab.cursorLine}, Col ${activeTab.cursorColumn}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                const SizedBox(width: 12),
                Text(
                  'Spaces: 2',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                const SizedBox(width: 12),
                Text(
                  'UTF-8',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                const SizedBox(width: 12),
                Text(
                  _getLanguageDisplay(activeTab.language),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ] else ...[
                const Text(
                  'No file open',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],

              const SizedBox(width: 8),
              const Text(
                'VS Code Android',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getLanguageDisplay(String language) {
    final map = {
      'dart': 'Dart',
      'javascript': 'JavaScript',
      'typescript': 'TypeScript',
      'python': 'Python',
      'java': 'Java',
      'kotlin': 'Kotlin',
      'json': 'JSON',
      'xml': 'XML',
      'html': 'HTML',
      'css': 'CSS',
      'markdown': 'Markdown',
      'bash': 'Shell Script',
      'cpp': 'C++',
      'c': 'C',
      'go': 'Go',
      'rust': 'Rust',
      'ruby': 'Ruby',
      'php': 'PHP',
      'swift': 'Swift',
      'yaml': 'YAML',
      'plaintext': 'Plain Text',
    };
    return map[language] ?? language;
  }
}
