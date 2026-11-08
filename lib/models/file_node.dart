class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  List<FileNode> children;
  bool isExpanded;
  /// Non-null when listing this directory's children failed (e.g. EACCES).
  String? listError;

  FileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    List<FileNode>? children,
    this.isExpanded = false,
    this.listError,
  }) : children = children ?? [];

  FileNode copyWith({
    List<FileNode>? children,
    bool? isExpanded,
    String? listError,
  }) {
    return FileNode(
      name: name,
      path: path,
      isDirectory: isDirectory,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      listError: listError ?? this.listError,
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
