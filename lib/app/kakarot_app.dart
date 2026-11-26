import 'package:flutter/material.dart';

import '../features/migration/migration_home_screen.dart';

class KakarotApp extends StatelessWidget {
  const KakarotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kakarot Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6574D9),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF080B19),
        useMaterial3: true,
      ),
      home: const MigrationHomeScreen(),
    );
  }
}
