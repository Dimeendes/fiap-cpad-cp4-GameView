import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const GameViewApp());
}

class GameViewApp extends StatelessWidget {
  const GameViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GameView',
      theme: ThemeData(
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}