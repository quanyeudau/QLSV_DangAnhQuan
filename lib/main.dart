import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/student_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase only on non-web platforms. (We target Android sync.)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Log but continue: Firestore sync will be attempted only when Firebase initialized.
      debugPrint('Firebase initialize failed: $e');
    }
  }
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState? of(BuildContext context) => context.findAncestorStateOfType<MyAppState>();

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF00695C); // teal-ish seed for education app
    final lightScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    final darkScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);

    ThemeData buildTheme(ColorScheme scheme) => ThemeData(
          useMaterial3: true,
          colorScheme: scheme,
          appBarTheme: AppBarTheme(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            centerTitle: true,
            elevation: 2,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: scheme.secondary,
            foregroundColor: scheme.onSecondary,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý sinh viên',
      themeMode: _mode,
      theme: buildTheme(lightScheme),
      darkTheme: buildTheme(darkScheme),
      home: const StudentScreen(),
    );
  }
}
