import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/vscode_theme.dart';
import 'providers/editor_provider.dart';
import 'providers/file_provider.dart';
import 'screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: VSCodeTheme.activityBar,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: VSCodeTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const VSCodeAndroidApp());
}

class VSCodeAndroidApp extends StatelessWidget {
  const VSCodeAndroidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EditorProvider()),
        ChangeNotifierProvider(create: (_) => FileProvider()),
      ],
      child: MaterialApp(
        title: 'VS Code Android',
        debugShowCheckedModeBanner: false,
        theme: VSCodeTheme.theme,
        darkTheme: VSCodeTheme.theme,
        themeMode: ThemeMode.dark,
        home: const MainScreen(),
      ),
    );
  }
}
