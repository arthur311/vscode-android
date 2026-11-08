import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/vscode_theme.dart';
import '../../providers/editor_provider.dart';
import 'tab_bar_widget.dart';
import 'code_editor_widget.dart';

class EditorArea extends StatelessWidget {
  const EditorArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, editorProvider, _) {
        return Container(
          color: VSCodeTheme.background,
          child: Column(
            children: [
              const TabBarWidget(),
              Expanded(
                child: editorProvider.activeTab == null
                    ? const _WelcomeScreen()
                    : CodeEditorWidget(tab: editorProvider.activeTab!),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VSCodeTheme.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // VS Code logo approximation
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: VSCodeTheme.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: VSCodeTheme.accentBlue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.code,
                size: 48,
                color: VSCodeTheme.accentBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'VS Code Android',
              style: TextStyle(
                color: VSCodeTheme.text,
                fontSize: 28,
                fontWeight: FontWeight.w300,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Code editor for Android',
              style: TextStyle(
                color: VSCodeTheme.textDim,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 40),
            _WelcomeSection(
              title: 'Start',
              items: [
                _WelcomeItem(
                  icon: Icons.note_add_outlined,
                  label: 'New File',
                  onTap: () => context.read<EditorProvider>().newUntitledFile(),
                ),
                _WelcomeItem(
                  icon: Icons.folder_open_outlined,
                  label: 'Open Folder',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _WelcomeSection(
              title: 'Help',
              items: [
                _InfoItem(
                  icon: Icons.keyboard,
                  label: 'Ctrl+S  Save file',
                ),
                _InfoItem(
                  icon: Icons.terminal,
                  label: 'Toggle terminal panel',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _WelcomeSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: VSCodeTheme.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }
}

class _WelcomeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _WelcomeItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: VSCodeTheme.accentBlue),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: VSCodeTheme.accentBlue,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: VSCodeTheme.textDim),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: VSCodeTheme.textDim,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
