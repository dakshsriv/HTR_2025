import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/preferences_service.dart';
import 'providers/task_provider.dart';
import 'providers/timer_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize preferences service
  final prefsService = PreferencesService();
  await prefsService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<PreferencesService>(create: (_) => prefsService),
        ChangeNotifierProvider<TaskProvider>(
          create: (_) => TaskProvider(prefsService: prefsService),
        ),
        ChangeNotifierProvider<TimerProvider>(
          create: (_) => TimerProvider(),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

/// Main application widget with Material Design theme and dark mode support.
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _isDarkMode = false;
  double _textScale = 1.0;

  @override
  void initState() {
    super.initState();
    // Initialize task provider on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().initialize();
    });
  }

  /// Toggle dark mode and update theme.
  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  /// Update text scale factor globally.
  void _setTextScale(double scale) {
    setState(() {
      _textScale = scale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Clockwork: Stop Planning, Start Doing',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: lightColorScheme,
        fontFamily: 'Roboto',
        // Improve bottom navigation bar visibility in light mode
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: lightColorScheme.surface,
          selectedItemColor: lightColorScheme.primary,
          unselectedItemColor: lightColorScheme.onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: darkColorScheme,
        fontFamily: 'Roboto',
        // Improve bottom navigation bar visibility in dark mode
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: darkColorScheme.surface,
          selectedItemColor: darkColorScheme.primary,
          unselectedItemColor: darkColorScheme.onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: _textScale,
          ),
          child: child!,
        );
      },
      home: HomeScreen(
        onThemeToggle: _toggleDarkMode,
        isDarkMode: _isDarkMode,
        onTextScaleChange: _setTextScale,
        textScale: _textScale,
      ),
    );
  }
}
