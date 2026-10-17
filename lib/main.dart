import 'package:flutter/material.dart';

import 'data/preferences_task_repository.dart';
import 'data/task_repository.dart';
import 'ui/taskflow_home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(TaskFlowApp(repository: PreferencesTaskRepository()));
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key, required this.repository});

  final TaskRepository repository;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF185C4B);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      surface: const Color(0xFFFBFCFA),
    );

    return MaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F6F2),
        fontFamily: 'Aptos',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F6F2),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE3E8E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE3E8E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: seed, width: 1.4),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE8ECE5)),
          ),
        ),
        dividerColor: const Color(0xFFE9EDE7),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: TaskFlowHome(repository: repository),
    );
  }
}
