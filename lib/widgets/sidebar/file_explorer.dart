import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/vscode_theme.dart';
import '../../models/file_node.dart';
import '../../providers/file_provider.dart';
import '../../providers/editor_provider.dart';
import '../../services/storage_permission_service.dart';

class FileExplorer extends StatelessWidget {
  const FileExplorer({super.key});

  Future<void> _openWithPermission(
      BuildContext context, FileProvider fileProvider) async {
    final granted =
        await StoragePermissionService.requestPermission(context);
    if (!granted && context.mounted) {
      StoragePermissionService.showDeniedSnackBar(context);
    }
    // Even if denied, still open picker — user may pick from app-private dirs
    if (context.mounted) {
      await fileProvider.pickAndOpenDirectory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, fileProvider, _) {
        return Container(
          color: VSCodeTheme.sidebar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ExplorerHeader(fileProvider: fileProvider),
              Expanded(
                child: fileProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: VSCodeTheme.accentBlue,
                          strokeWidth: 2,
                        ),
                      )
                    : fileProvider.rootPath == null
                        ? _EmptyExplorer(onOpenFolder: () {
                            _openWithPermission(context, fileProvider);
                          })
                        : fileProvider.fileTree.isEmpty
                            ? const Center(
                                child: Text(
                                  'Empty folder',
                                  style: TextStyle(
                                    color: VSCodeTheme.textDim,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : _FileTree(nodes: fileProvider.fileTree),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExplorerHeader extends StatelessWidget {
  final FileProvider fileProvider;

  const _ExplorerHeader({required this.fileProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: VSCodeTheme.sidebar,
        border: Border(
          bottom: BorderSide(color: VSCodeTheme.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              fileProvider.rootName,
              style: const TextStyle(
                color: VSCodeTheme.textDim,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _HeaderAction(
            icon: Icons.create_new_folder_outlined,
            tooltip: 'New Folder',
            onTap: () => _showCreateDialog(context, true),
          ),
          _HeaderAction(
            icon: Icons.note_add_outlined,
            tooltip: 'New File',
            onTap: () => _showCreateDialog(context, false),
          ),
          _HeaderAction(
            icon: Icons.folder_open_outlined,
            tooltip: 'Open Folder',
            onTap: () async {
              final granted = await StoragePermissionService.requestPermission(context);
              if (!granted && context.mounted) {
                StoragePermissionService.showDeniedSnackBar(context);
              }
              if (context.mounted) {
                await fileProvider.pickAndOpenDirectory();
              }
            },
          ),
          _HeaderAction(
            icon: Icons.refresh,
            tooltip: 'Refresh',
            onTap: () => fileProvider.refreshTree(),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, bool isFolder) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VSCodeTheme.sidebar,
        title: Text(
          isFolder ? 'New Folder' : 'New File',
          style: const TextStyle(color: VSCodeTheme.text, fontSize: 14),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: VSCodeTheme.text, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Enter name',
            hintStyle: TextStyle(color: VSCodeTheme.textDim),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: VSCodeTheme.accentBlue),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: VSCodeTheme.accentBlue),
            ),
          ),
          onSubmitted: (value) {
            Navigator.of(ctx).pop();
            final basePath = fileProvider.rootPath ?? '/tmp';
            if (isFolder) {
              fileProvider.createFolder(basePath, value);
            } else {
              fileProvider.createFile(basePath, value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: VSCodeTheme.textDim)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final basePath = fileProvider.rootPath ?? '/tmp';
              if (isFolder) {
                fileProvider.createFolder(basePath, controller.text);
              } else {
                fileProvider.createFile(basePath, controller.text);
              }
            },
            child: const Text('Create', style: TextStyle(color: VSCodeTheme.accentBlue)),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(icon, size: 16, color: VSCodeTheme.textDim),
        ),
      ),
    );
  }
}

class _EmptyExplorer extends StatelessWidget {
  final VoidCallback onOpenFolder;

  const _EmptyExplorer({required this.onOpenFolder});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_open,
            size: 48,
            color: VSCodeTheme.textDim,
          ),
          const SizedBox(height: 12),
          const Text(
            'No folder opened',
            style: TextStyle(color: VSCodeTheme.textDim, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onOpenFolder,
            style: ElevatedButton.styleFrom(
              backgroundColor: VSCodeTheme.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('Open Folder'),
          ),
        ],
      ),
    );
  }
}

class _FileTree extends StatelessWidget {
  final List<FileNode> nodes;

  const _FileTree({required this.nodes});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        return _FileNodeTile(node: nodes[index], depth: 0);
      },
    );
  }
}

class _FileNodeTile extends StatefulWidget {
  final FileNode node;
  final int depth;

  const _FileNodeTile({required this.node, required this.depth});

  @override
  State<_FileNodeTile> createState() => _FileNodeTileState();
}

class _FileNodeTileState extends State<_FileNodeTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final indentPx = 8.0 + widget.depth * 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () => _handleTap(context),
            onLongPress: () => _showContextMenu(context),
            child: Container(
              height: 22,
              color: _isHovered ? VSCodeTheme.lineHighlight : Colors.transparent,
              padding: EdgeInsets.only(left: indentPx, right: 8),
              child: Row(
                children: [
                  if (node.isDirectory) ...[
                    Icon(
                      node.isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 16,
                      color: VSCodeTheme.textDim,
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      node.isExpanded
                          ? Icons.folder_open
                          : Icons.folder,
                      size: 16,
                      color: VSCodeTheme.folderYellow,
                    ),
                  ] else ...[
                    const SizedBox(width: 18),
                    Icon(
                      _fileIcon(node.name),
                      size: 16,
                      color: VSCodeTheme.fileIconColor(node.name),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      node.name,
                      style: const TextStyle(
                        color: VSCodeTheme.text,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (node.isDirectory && node.isExpanded && node.children.isNotEmpty)
          Column(
            children: node.children
                .map((child) => _FileNodeTile(node: child, depth: widget.depth + 1))
                .toList(),
          ),
      ],
    );
  }

  void _handleTap(BuildContext context) {
    if (widget.node.isDirectory) {
      context.read<FileProvider>().toggleDirectory(widget.node);
    } else {
      context.read<EditorProvider>().openFile(widget.node.path);
    }
  }

  void _showContextMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + renderBox.size.width,
        offset.dy + renderBox.size.height,
      ),
      color: VSCodeTheme.sidebar,
      items: [
        PopupMenuItem(
          value: 'delete',
          child: const Text(
            'Delete',
            style: TextStyle(color: VSCodeTheme.text, fontSize: 13),
          ),
          onTap: () {
            context.read<FileProvider>().deleteNode(widget.node);
          },
        ),
      ],
    );
  }

  IconData _fileIcon(String filename) {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'dart':
      case 'js':
      case 'ts':
      case 'py':
      case 'java':
      case 'kt':
      case 'cpp':
      case 'c':
      case 'go':
      case 'rs':
      case 'rb':
      case 'php':
      case 'swift':
        return Icons.code;
      case 'json':
      case 'yaml':
      case 'yml':
        return Icons.data_object;
      case 'xml':
      case 'html':
        return Icons.html;
      case 'css':
      case 'scss':
        return Icons.css;
      case 'md':
        return Icons.article_outlined;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return Icons.image_outlined;
      case 'sh':
      case 'bash':
        return Icons.terminal;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}
