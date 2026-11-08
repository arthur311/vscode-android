class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  List<FileNode> children;
  bool isExpanded;

  FileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    List<FileNode>? children,
    this.isExpanded = false,
  }) : children = children ?? [];

  FileNode copyWith({
    List<FileNode>? children,
    bool? isExpanded,
  }) {
    return FileNode(
      name: name,
      path: path,
      isDirectory: isDirectory,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileNode && runtimeType == other.runtimeType && path == other.path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'FileNode(name: $name, isDirectory: $isDirectory)';
}
