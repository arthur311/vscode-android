import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/vscode_theme.dart';

class TerminalWidget extends StatefulWidget {
  const TerminalWidget({super.key});

  @override
  State<TerminalWidget> createState() => _TerminalWidgetState();
}

class _TerminalWidgetState extends State<TerminalWidget> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  final List<_TerminalLine> _lines = [];
  String _currentDirectory = '/';
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _initTerminal();
  }

  Future<void> _initTerminal() async {
    try {
      if (Platform.isAndroid) {
        _currentDirectory = '/storage/emulated/0';
        final dir = Directory(_currentDirectory);
        if (!await dir.exists()) {
          _currentDirectory = '/data/data';
        }
      } else {
        _currentDirectory = Directory.current.path;
      }
    } catch (_) {
      _currentDirectory = '/';
    }

    _addLine('\x1B[1;32mVSCode Android Terminal\x1B[0m', isSystem: true);
    _addLine('Type commands below. pwd, ls, cat, echo are supported.', isSystem: true);
    _addLine('', isSystem: true);
    _printPrompt();
  }

  void _addLine(String text, {bool isInput = false, bool isSystem = false, bool isError = false}) {
    setState(() {
      _lines.add(_TerminalLine(
        text: text,
        isInput: isInput,
        isSystem: isSystem,
        isError: isError,
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _printPrompt() {
    // Prompt is shown in the input row
  }

  Future<void> _runCommand(String command) async {
    if (command.trim().isEmpty) {
      _addLine('', isInput: true);
      return;
    }

    final prompt = '\$ $_currentDirectory > $command';
    _addLine(prompt, isInput: true);

    final parts = command.trim().split(RegExp(r'\s+'));
    final cmd = parts[0];
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];

    setState(() => _isRunning = true);

    try {
      if (cmd == 'cd') {
        await _handleCd(args);
      } else if (cmd == 'clear' || cmd == 'cls') {
        setState(() => _lines.clear());
        _printPrompt();
      } else if (cmd == 'pwd') {
        _addLine(_currentDirectory);
      } else if (cmd == 'echo') {
        _addLine(args.join(' '));
      } else if (cmd == 'help') {
        _showHelp();
      } else {
        await _executeSystemCommand(cmd, args);
      }
    } catch (e) {
      _addLine('Error: $e', isError: true);
    } finally {
      setState(() => _isRunning = false);
    }
  }

  Future<void> _handleCd(List<String> args) async {
    if (args.isEmpty) {
      if (Platform.isAndroid) {
        _currentDirectory = '/storage/emulated/0';
      } else {
        _currentDirectory = Platform.environment['HOME'] ?? '/';
      }
      return;
    }

    final target = args[0];
    String newPath;

    if (target == '..') {
      final parent = Directory(_currentDirectory).parent.path;
      newPath = parent;
    } else if (target.startsWith('/')) {
      newPath = target;
    } else {
      newPath = '$_currentDirectory/$target';
    }

    final dir = Directory(newPath);
    if (await dir.exists()) {
      setState(() => _currentDirectory = dir.path);
    } else {
      _addLine('cd: $target: No such directory', isError: true);
    }
  }

  Future<void> _executeSystemCommand(String cmd, List<String> args) async {
    try {
      final result = await Process.run(
        cmd,
        args,
        workingDirectory: _currentDirectory,
        runInShell: true,
      );

      if (result.stdout.toString().isNotEmpty) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.isNotEmpty) {
            _addLine(line);
          }
        }
      }

      if (result.stderr.toString().isNotEmpty) {
        final errLines = result.stderr.toString().split('\n');
        for (final line in errLines) {
          if (line.isNotEmpty) {
            _addLine(line, isError: true);
          }
        }
      }

      if (result.exitCode != 0 && result.stdout.toString().isEmpty && result.stderr.toString().isEmpty) {
        _addLine('Command exited with code ${result.exitCode}', isError: true);
      }
    } on ProcessException {
      _addLine('$cmd: command not found', isError: true);
    } catch (e) {
      _addLine('Error running command: $e', isError: true);
    }
  }

  void _showHelp() {
    _addLine('Available commands:', isSystem: true);
    _addLine('  pwd          - Print working directory', isSystem: true);
    _addLine('  ls [path]    - List directory', isSystem: true);
    _addLine('  cd [path]    - Change directory', isSystem: true);
    _addLine('  cat [file]   - Print file contents', isSystem: true);
    _addLine('  echo [text]  - Print text', isSystem: true);
    _addLine('  clear        - Clear terminal', isSystem: true);
    _addLine('  help         - Show this help', isSystem: true);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VSCodeTheme.terminalBackground,
      child: Column(
        children: [
          // Terminal header
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF252526),
              border: Border(
                top: BorderSide(color: VSCodeTheme.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 14, color: VSCodeTheme.textDim),
                const SizedBox(width: 6),
                const Text(
                  'TERMINAL',
                  style: TextStyle(
                    color: VSCodeTheme.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    setState(() => _lines.clear());
                    _printPrompt();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 14, color: VSCodeTheme.textDim),
                  ),
                ),
              ],
            ),
          ),
          // Terminal output
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _lines.length,
              itemBuilder: (context, index) {
                final line = _lines[index];
                return _TerminalLineWidget(line: line);
              },
            ),
          ),
          // Input row
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: VSCodeTheme.border, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Text(
                  '\$ ',
                  style: const TextStyle(
                    color: Color(0xFF4EC9B0),
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    enabled: !_isRunning,
                    style: const TextStyle(
                      color: VSCodeTheme.text,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Enter command...',
                      hintStyle: TextStyle(
                        color: VSCodeTheme.textDim,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    cursorColor: Colors.white,
                    onSubmitted: (value) {
                      _inputController.clear();
                      _runCommand(value);
                      _inputFocusNode.requestFocus();
                    },
                  ),
                ),
                if (_isRunning)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: VSCodeTheme.accentBlue,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalLine {
  final String text;
  final bool isInput;
  final bool isSystem;
  final bool isError;

  const _TerminalLine({
    required this.text,
    this.isInput = false,
    this.isSystem = false,
    this.isError = false,
  });
}

class _TerminalLineWidget extends StatelessWidget {
  final _TerminalLine line;

  const _TerminalLineWidget({required this.line});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (line.isError) {
      color = VSCodeTheme.errorRed;
    } else if (line.isInput) {
      color = const Color(0xFF4EC9B0);
    } else if (line.isSystem) {
      color = const Color(0xFF569CD6);
    } else {
      color = VSCodeTheme.text;
    }

    return Text(
      line.text,
      style: TextStyle(
        color: color,
        fontFamily: 'monospace',
        fontSize: 13,
        height: 1.4,
      ),
    );
  }
}
