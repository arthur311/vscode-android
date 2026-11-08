import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/go.dart';
import 'package:re_highlight/languages/rust.dart';
import 'package:re_highlight/languages/yaml.dart';
import '../../theme/vscode_theme.dart';
import '../../models/editor_tab.dart';
import '../../providers/editor_provider.dart';

class CodeEditorWidget extends StatefulWidget {
  final EditorTab tab;

  const CodeEditorWidget({super.key, required this.tab});

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late TextEditingController _controller;
  final ScrollController _verticalScroll = ScrollController();
  final ScrollController _horizontalScroll = ScrollController();
  final FocusNode _focusNode = FocusNode();

  static final Highlight _highlighter = _buildHighlighter();

  static const Map<String, TextStyle> _vscodeDark = {
    'keyword': TextStyle(color: Color(0xFF569CD6)),
    'built_in': TextStyle(color: Color(0xFF4EC9B0)),
    'type': TextStyle(color: Color(0xFF4EC9B0)),
    'literal': TextStyle(color: Color(0xFF569CD6)),
    'number': TextStyle(color: Color(0xFFB5CEA8)),
    'regexp': TextStyle(color: Color(0xFFD16969)),
    'string': TextStyle(color: Color(0xFFCE9178)),
    'subst': TextStyle(color: Color(0xFFD4D4D4)),
    'symbol': TextStyle(color: Color(0xFFD4D4D4)),
    'class': TextStyle(color: Color(0xFF4EC9B0)),
    'function': TextStyle(color: Color(0xFFDCDCAA)),
    'title': TextStyle(color: Color(0xFFDCDCAA)),
    'params': TextStyle(color: Color(0xFFD4D4D4)),
    'comment': TextStyle(color: Color(0xFF6A9955)),
    'doctag': TextStyle(color: Color(0xFF6A9955)),
    'meta': TextStyle(color: Color(0xFF9CDCFE)),
    'section': TextStyle(color: Color(0xFF4EC9B0)),
    'tag': TextStyle(color: Color(0xFF808080)),
    'name': TextStyle(color: Color(0xFF569CD6)),
    'attr': TextStyle(color: Color(0xFF9CDCFE)),
    'attribute': TextStyle(color: Color(0xFF9CDCFE)),
    'variable': TextStyle(color: Color(0xFF9CDCFE)),
    'addition': TextStyle(color: Color(0xFFB5CEA8)),
    'deletion': TextStyle(color: Color(0xFFF44747)),
    'selector-tag': TextStyle(color: Color(0xFFD7BA7D)),
    'selector-id': TextStyle(color: Color(0xFFD7BA7D)),
    'selector-class': TextStyle(color: Color(0xFFD7BA7D)),
    'template-variable': TextStyle(color: Color(0xFF9CDCFE)),
  };

  static const TextStyle _baseStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    height: 1.5,
    color: VSCodeTheme.text,
  );

  static Highlight _buildHighlighter() {
    final hl = Highlight();
    hl.registerLanguage('dart', langDart);
    hl.registerLanguage('javascript', langJavascript);
    hl.registerLanguage('typescript', langTypescript);
    hl.registerLanguage('python', langPython);
    hl.registerLanguage('java', langJava);
    hl.registerLanguage('json', langJson);
    hl.registerLanguage('xml', langXml);
    hl.registerLanguage('css', langCss);
    hl.registerLanguage('markdown', langMarkdown);
    hl.registerLanguage('bash', langBash);
    hl.registerLanguage('cpp', langCpp);
    hl.registerLanguage('go', langGo);
    hl.registerLanguage('rust', langRust);
    hl.registerLanguage('yaml', langYaml);
    return hl;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tab.content);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(CodeEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.id != widget.tab.id) {
      _controller.removeListener(_onTextChanged);
      _controller.dispose();
      _controller = TextEditingController(text: widget.tab.content);
      _controller.addListener(_onTextChanged);
    } else if (!widget.tab.isModified && widget.tab.content != _controller.text) {
      _controller.value = _controller.value.copyWith(text: widget.tab.content);
    }
  }

  void _onTextChanged() {
    final newContent = _controller.text;
    if (newContent != widget.tab.content) {
      context.read<EditorProvider>().updateContent(widget.tab.id, newContent);
      setState(() {}); // rebuild for highlighted overlay
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  TextSpan? _buildHighlightedSpan(String code, String language) {
    if (!_highlighter.listLanguages().contains(language)) return null;
    try {
      final result = _highlighter.highlight(
        code: code,
        language: language,
        ignoreIllegals: true,
      );
      final renderer = TextSpanRenderer(_baseStyle, _vscodeDark);
      result.render(renderer);
      return renderer.span;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyS &&
            HardwareKeyboard.instance.isControlPressed) {
          context.read<EditorProvider>().saveActiveTab();
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line numbers
          _LineNumbers(content: widget.tab.content),
          // Editor content
          Expanded(
            child: Scrollbar(
              controller: _verticalScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalScroll,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 50,
                    ),
                    child: _buildEditorStack(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorStack(BuildContext context) {
    final highlighted = _buildHighlightedSpan(widget.tab.content, widget.tab.language);

    if (highlighted == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: _baseStyle,
          cursorColor: Colors.white,
                    decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Stack(
        children: [
          // Highlighted background
          RichText(
            text: highlighted,
            softWrap: false,
          ),
          // Transparent input overlay
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: _baseStyle.copyWith(color: Colors.transparent),
            cursorColor: Colors.white,
                        decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineNumbers extends StatelessWidget {
  final String content;

  const _LineNumbers({required this.content});

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final count = lines.isEmpty ? 1 : lines.length;

    return Container(
      color: const Color(0xFF1E1E1E),
      width: 50,
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(count, (i) {
          return Text(
            '${i + 1}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              height: 1.5,
              color: VSCodeTheme.textDim,
            ),
          );
        }),
      ),
    );
  }
}
