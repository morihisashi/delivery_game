import 'package:flutter/material.dart';

import 'screens/game_screen.dart';

void main() {
  runApp(const DeliveryGameApp());
}

class DeliveryGameApp extends StatelessWidget {
  const DeliveryGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delivery Game',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const GameScreen(),
    );
  }
}
