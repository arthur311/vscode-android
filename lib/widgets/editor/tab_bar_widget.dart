import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/vscode_theme.dart';
import '../../models/editor_tab.dart';
import '../../providers/editor_provider.dart';

class TabBarWidget extends StatelessWidget {
  const TabBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, editorProvider, _) {
        final tabs = editorProvider.tabs;
        if (tabs.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 35,
          color: VSCodeTheme.tabInactive,
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: tabs.map((tab) {
                      final isActive = tab.id == editorProvider.activeTabId;
                      return _TabItem(
                        tab: tab,
                        isActive: isActive,
                        onTap: () => editorProvider.setActiveTab(tab.id),
                        onClose: () => editorProvider.closeTab(tab.id),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabItem extends StatefulWidget {
  final EditorTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 80, maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isActive ? VSCodeTheme.tabActive : VSCodeTheme.tabInactive,
            border: Border(
              right: const BorderSide(color: VSCodeTheme.border, width: 0.5),
              top: BorderSide(
                color: widget.isActive ? VSCodeTheme.accentBlue : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modified dot
              if (widget.tab.isModified)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              // Filename
              Text(
                widget.tab.filename,
                style: TextStyle(
                  color: widget.isActive ? VSCodeTheme.text : VSCodeTheme.textDim,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 6),
              // Close button
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: _isHovered
                        ? VSCodeTheme.border
                        : Colors.transparent,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 12,
                    color: widget.isActive || _isHovered
                        ? VSCodeTheme.text
                        : Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
