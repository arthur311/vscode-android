import 'package:flutter/material.dart';

class VSCodeTheme {
  static const Color background = Color(0xFF1E1E1E);
  static const Color sidebar = Color(0xFF252526);
  static const Color activityBar = Color(0xFF333333);
  static const Color tabActive = Color(0xFF1E1E1E);
  static const Color tabInactive = Color(0xFF2D2D2D);
  static const Color text = Color(0xFFD4D4D4);
  static const Color textDim = Color(0xFF858585);
  static const Color accentBlue = Color(0xFF007ACC);
  static const Color statusBar = Color(0xFF007ACC);
  static const Color border = Color(0xFF3C3C3C);
  static const Color selection = Color(0xFF264F78);
  static const Color lineHighlight = Color(0xFF2A2D2E);
  static const Color terminalBackground = Color(0xFF1E1E1E);
  static const Color terminalText = Color(0xFF4EC9B0);
  static const Color folderYellow = Color(0xFFDCB67A);
  static const Color iconBlue = Color(0xFF519ABA);
  static const Color errorRed = Color(0xFFF44747);
  static const Color warningYellow = Color(0xFFCCA700);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accentBlue,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        surface: background,
        onSurface: text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: activityBar,
        foregroundColor: text,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: text, fontFamily: 'monospace'),
        bodySmall: TextStyle(color: textDim, fontFamily: 'monospace'),
      ),
      iconTheme: const IconThemeData(color: textDim, size: 20),
      dividerColor: border,
    );
  }

  // Language-specific icon colors
  static Color fileIconColor(String filename) {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'dart':
        return const Color(0xFF54C5F8);
      case 'js':
      case 'ts':
        return const Color(0xFFF7DF1E);
      case 'py':
        return const Color(0xFF3572A5);
      case 'java':
        return const Color(0xFFB07219);
      case 'kt':
        return const Color(0xFFA97BFF);
      case 'json':
        return const Color(0xFFCBCB41);
      case 'xml':
      case 'html':
        return const Color(0xFFE34C26);
      case 'css':
      case 'scss':
        return const Color(0xFF563D7C);
      case 'md':
        return const Color(0xFF083FA1);
      case 'yaml':
      case 'yml':
        return const Color(0xFFCB171E);
      case 'sh':
      case 'bash':
        return const Color(0xFF89E051);
      default:
        return textDim;
    }
  }

  // Map file extension to language mode name
  static String languageFromExtension(String filename) {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'dart':
        return 'dart';
      case 'js':
        return 'javascript';
      case 'ts':
        return 'typescript';
      case 'py':
        return 'python';
      case 'java':
        return 'java';
      case 'kt':
        return 'kotlin';
      case 'json':
        return 'json';
      case 'xml':
        return 'xml';
      case 'html':
        return 'html';
      case 'css':
        return 'css';
      case 'scss':
        return 'scss';
      case 'md':
        return 'markdown';
      case 'yaml':
      case 'yml':
        return 'yaml';
      case 'sh':
      case 'bash':
        return 'bash';
      case 'cpp':
      case 'cc':
        return 'cpp';
      case 'c':
        return 'c';
      case 'go':
        return 'go';
      case 'rs':
        return 'rust';
      case 'rb':
        return 'ruby';
      case 'php':
        return 'php';
      case 'swift':
        return 'swift';
      default:
        return 'plaintext';
    }
  }
}
