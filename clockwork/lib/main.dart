import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/preferences_service.dart';
import 'providers/task_provider.dart';
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
      ],
      child: const MainApp(),
    ),
  );
}

/// Main application widget with Material Design theme.
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    // Initialize task provider on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flow Anchor',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}
