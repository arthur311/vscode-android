import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/vscode_theme.dart';
import '../providers/editor_provider.dart';
import '../widgets/activity_bar.dart';
import '../widgets/sidebar/file_explorer.dart';
import '../widgets/editor/editor_area.dart';
import '../widgets/terminal/terminal_widget.dart';
import '../widgets/status_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  ActivityBarItem _activeActivityItem = ActivityBarItem.files;
  bool _sidebarVisible = true;
  bool _terminalVisible = false;
  double _sidebarWidth = 240;
  double _terminalHeight = 220;
  bool _isDraggingSidebar = false;
  bool _isDraggingTerminal = false;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          // Toggle terminal: Ctrl+`
          if (event.logicalKey == LogicalKeyboardKey.backquote &&
              HardwareKeyboard.instance.isControlPressed) {
            setState(() => _terminalVisible = !_terminalVisible);
          }
          // Save: Ctrl+S
          if (event.logicalKey == LogicalKeyboardKey.keyS &&
              HardwareKeyboard.instance.isControlPressed) {
            context.read<EditorProvider>().saveActiveTab();
          }
          // Toggle sidebar: Ctrl+B
          if (event.logicalKey == LogicalKeyboardKey.keyB &&
              HardwareKeyboard.instance.isControlPressed) {
            setState(() => _sidebarVisible = !_sidebarVisible);
          }
        }
      },
      child: Scaffold(
        backgroundColor: VSCodeTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Activity Bar
                    ActivityBar(
                      activeItem: _activeActivityItem,
                      onItemTap: (item) {
                        setState(() {
                          if (_activeActivityItem == item && _sidebarVisible) {
                            _sidebarVisible = false;
                          } else {
                            _activeActivityItem = item;
                            _sidebarVisible = true;
                          }
                        });
                      },
                    ),

                    // Sidebar
                    if (_sidebarVisible) ...[
                      _buildSidebar(),
                      // Resize handle
                      GestureDetector(
                        onHorizontalDragStart: (_) =>
                            setState(() => _isDraggingSidebar = true),
                        onHorizontalDragEnd: (_) =>
                            setState(() => _isDraggingSidebar = false),
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _sidebarWidth =
                                (_sidebarWidth + details.delta.dx).clamp(120.0, 400.0);
                          });
                        },
                        child: Container(
                          width: 4,
                          color: _isDraggingSidebar
                              ? VSCodeTheme.accentBlue
                              : VSCodeTheme.border,
                          child: const MouseRegion(
                            cursor: SystemMouseCursors.resizeColumn,
                            child: SizedBox.expand(),
                          ),
                        ),
                      ),
                    ],

                    // Main editor + terminal column
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: const EditorArea(),
                          ),
                          if (_terminalVisible) ...[
                            // Terminal resize handle
                            GestureDetector(
                              onVerticalDragStart: (_) =>
                                  setState(() => _isDraggingTerminal = true),
                              onVerticalDragEnd: (_) =>
                                  setState(() => _isDraggingTerminal = false),
                              onVerticalDragUpdate: (details) {
                                setState(() {
                                  _terminalHeight =
                                      (_terminalHeight - details.delta.dy).clamp(80.0, 500.0);
                                });
                              },
                              child: Container(
                                height: 4,
                                color: _isDraggingTerminal
                                    ? VSCodeTheme.accentBlue
                                    : VSCodeTheme.border,
                                child: const MouseRegion(
                                  cursor: SystemMouseCursors.resizeRow,
                                  child: SizedBox.expand(),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: _terminalHeight,
                              child: const TerminalWidget(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Status Bar
              const StatusBar(),
            ],
          ),
        ),
        // FAB to toggle terminal
        floatingActionButton: FloatingActionButton.small(
          onPressed: () => setState(() => _terminalVisible = !_terminalVisible),
          backgroundColor: _terminalVisible
              ? VSCodeTheme.accentBlue
              : VSCodeTheme.sidebar,
          tooltip: 'Toggle Terminal',
          child: const Icon(Icons.terminal, size: 18),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: _sidebarWidth,
      child: _buildSidebarContent(),
    );
  }

  Widget _buildSidebarContent() {
    switch (_activeActivityItem) {
      case ActivityBarItem.files:
        return const FileExplorer();
      case ActivityBarItem.search:
        return const _SearchPanel();
      case ActivityBarItem.sourceControl:
        return const _SourceControlPanel();
      case ActivityBarItem.extensions:
        return const _ExtensionsPanel();
      case ActivityBarItem.settings:
        return const _SettingsPanel();
    }
  }
}

class _SearchPanel extends StatefulWidget {
  const _SearchPanel();

  @override
  State<_SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<_SearchPanel> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: VSCodeTheme.sidebar,
      child: Column(
        children: [
          Container(
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: VSCodeTheme.border, width: 0.5)),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SEARCH',
                style: TextStyle(
                  color: VSCodeTheme.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: VSCodeTheme.text, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(color: VSCodeTheme.textDim, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 16, color: VSCodeTheme.textDim),
                filled: true,
                fillColor: VSCodeTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              cursorColor: VSCodeTheme.accentBlue,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'No results',
                style: TextStyle(color: VSCodeTheme.textDim, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceControlPanel extends StatelessWidget {
  const _SourceControlPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VSCodeTheme.sidebar,
      child: Column(
        children: [
          Container(
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: VSCodeTheme.border, width: 0.5)),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SOURCE CONTROL',
                style: TextStyle(
                  color: VSCodeTheme.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_tree_outlined, size: 48, color: VSCodeTheme.textDim),
                  SizedBox(height: 12),
                  Text(
                    'No source control',
                    style: TextStyle(color: VSCodeTheme.textDim, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtensionsPanel extends StatelessWidget {
  const _ExtensionsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VSCodeTheme.sidebar,
      child: Column(
        children: [
          Container(
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: VSCodeTheme.border, width: 0.5)),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'EXTENSIONS',
                style: TextStyle(
                  color: VSCodeTheme.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.extension_outlined, size: 48, color: VSCodeTheme.textDim),
                  SizedBox(height: 12),
                  Text(
                    'Extensions coming soon',
                    style: TextStyle(color: VSCodeTheme.textDim, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VSCodeTheme.sidebar,
      child: Column(
        children: [
          Container(
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: VSCodeTheme.border, width: 0.5)),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SETTINGS',
                style: TextStyle(
                  color: VSCodeTheme.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: const [
                _SettingItem(
                  label: 'Font Size',
                  value: '14',
                ),
                _SettingItem(
                  label: 'Tab Size',
                  value: '2',
                ),
                _SettingItem(
                  label: 'Word Wrap',
                  value: 'off',
                ),
                _SettingItem(
                  label: 'Line Numbers',
                  value: 'on',
                ),
                _SettingItem(
                  label: 'Theme',
                  value: 'Dark+ (default dark)',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String label;
  final String value;

  const _SettingItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: VSCodeTheme.text, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: VSCodeTheme.textDim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
