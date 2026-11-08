import 'package:flutter/material.dart';
import '../theme/vscode_theme.dart';

enum ActivityBarItem {
  files,
  search,
  sourceControl,
  extensions,
  settings,
}

class ActivityBar extends StatelessWidget {
  final ActivityBarItem activeItem;
  final ValueChanged<ActivityBarItem> onItemTap;

  const ActivityBar({
    super.key,
    required this.activeItem,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      color: VSCodeTheme.activityBar,
      child: Column(
        children: [
          const SizedBox(height: 8),
          _ActivityBarButton(
            icon: Icons.insert_drive_file_outlined,
            tooltip: 'Explorer',
            isActive: activeItem == ActivityBarItem.files,
            onTap: () => onItemTap(ActivityBarItem.files),
          ),
          _ActivityBarButton(
            icon: Icons.search,
            tooltip: 'Search',
            isActive: activeItem == ActivityBarItem.search,
            onTap: () => onItemTap(ActivityBarItem.search),
          ),
          _ActivityBarButton(
            icon: Icons.account_tree_outlined,
            tooltip: 'Source Control',
            isActive: activeItem == ActivityBarItem.sourceControl,
            onTap: () => onItemTap(ActivityBarItem.sourceControl),
          ),
          _ActivityBarButton(
            icon: Icons.extension_outlined,
            tooltip: 'Extensions',
            isActive: activeItem == ActivityBarItem.extensions,
            onTap: () => onItemTap(ActivityBarItem.extensions),
          ),
          const Spacer(),
          _ActivityBarButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            isActive: activeItem == ActivityBarItem.settings,
            onTap: () => onItemTap(ActivityBarItem.settings),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActivityBarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  const _ActivityBarButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isActive ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isActive
                ? Colors.white
                : VSCodeTheme.textDim,
          ),
        ),
      ),
    );
  }
}
