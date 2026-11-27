import 'package:flutter/material.dart';
import '../features/auth/auth_gate.dart';

class KakarotApp extends StatelessWidget {
  const KakarotApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Kakarot Chat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF8C1A),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF070B1A),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      );
}
