import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles the MANAGE_EXTERNAL_STORAGE permission flow for Android 11+.
///
/// This permission cannot be granted via a standard runtime dialog — the OS
/// requires the user to navigate to Settings > Apps > Special app access >
/// All files access. This service checks the current state, shows an
/// explanation dialog, then opens the correct Settings screen.
class StoragePermissionService {
  /// Returns true if the app currently has all-files access.
  static Future<bool> hasPermission() async {
    return Permission.manageExternalStorage.isGranted;
  }

  /// Checks permission and, if not granted, shows an explanation dialog and
  /// opens Settings. Returns true if permission is already granted (or becomes
  /// granted after the user returns). Call this before accessing
  /// /storage/emulated/0.
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
            child: const Text(
              'Not now',
              style: TextStyle(color: Color(0xFF9CDCFE)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Open Settings',
              style: TextStyle(color: Color(0xFF007ACC)),
            ),
          ),
        ],
      ),
    );

    if (shouldOpen != true) return false;

    // Opens android.settings.MANAGE_ALL_FILES_ACCESS_PERMISSION
    await Permission.manageExternalStorage.request();

    // Re-check after user returns from Settings
    return Permission.manageExternalStorage.isGranted;
  }

  /// Shows a non-dismissible banner when permission was denied, so the user
  /// knows why the file explorer is empty.
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
          onPressed: openAppSettings,
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}
