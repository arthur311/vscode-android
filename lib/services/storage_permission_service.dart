import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('com.example.vscode_android/storage');

class StoragePermissionService {
  static Future<bool> hasPermission() async {
    final result = await _channel.invokeMethod<bool>('hasManageStoragePermission');
    return result ?? false;
  }

  /// Shows an explanation dialog, then opens the system Settings screen for
  /// MANAGE_EXTERNAL_STORAGE. Returns true only if already granted (the user
  /// must return from Settings and retry — we cannot observe the grant live).
  static Future<bool> requestPermission(BuildContext context) async {
    if (await hasPermission()) return true;

    if (!context.mounted) return false;
    final shouldOpen = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252526),
        title: const Text(
          'Storage Access Required',
          style: TextStyle(color: Color(0xFFD4D4D4), fontSize: 15),
        ),
        content: const Text(
          'Code&Terminal needs "All files access" to open and edit files '
          'anywhere on your device.\n\n'
          'Tap "Open Settings", then enable "Allow access to manage all files" '
          'for this app, and return here.',
          style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now',
                style: TextStyle(color: Color(0xFF9CDCFE))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Settings',
                style: TextStyle(color: Color(0xFF007ACC))),
          ),
        ],
      ),
    );

    if (shouldOpen != true) return false;
    await _channel.invokeMethod<void>('openManageStorageSettings');
    // Re-check after user returns from Settings.
    return hasPermission();
  }

  static void showDeniedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF3C3C3C),
        behavior: SnackBarBehavior.floating,
        content: const Text(
          'Storage access denied — only app-private folders are accessible.',
          style: TextStyle(color: Color(0xFFD4D4D4), fontSize: 12),
        ),
        action: SnackBarAction(
          label: 'Open Settings',
          textColor: const Color(0xFF007ACC),
          onPressed: () =>
              _channel.invokeMethod<void>('openManageStorageSettings'),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}
