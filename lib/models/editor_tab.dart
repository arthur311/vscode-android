class EditorTab {
  final String id;
  final String path;
  final String filename;
  String content;
  bool isModified;
  final String language;
  int cursorLine;
  int cursorColumn;

  EditorTab({
    required this.id,
    required this.path,
    required this.filename,
    required this.content,
    this.isModified = false,
    required this.language,
    this.cursorLine = 1,
    this.cursorColumn = 1,
  });

  EditorTab copyWith({
    String? content,
    bool? isModified,
    int? cursorLine,
    int? cursorColumn,
  }) {
    return EditorTab(
      id: id,
      path: path,
      filename: filename,
      content: content ?? this.content,
      isModified: isModified ?? this.isModified,
      language: language,
      cursorLine: cursorLine ?? this.cursorLine,
      cursorColumn: cursorColumn ?? this.cursorColumn,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorTab && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EditorTab(id: $id, filename: $filename, isModified: $isModified)';
}
