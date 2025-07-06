import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/historico_screen.dart'; // Import HistoricoScreen

void main() {
  runApp(const GhostStrideApp());
}

class GhostStrideApp extends StatelessWidget {
  const GhostStrideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GhostStride',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
      routes: {
        '/historico': (context) => const HistoricoScreen(),
      },
    );
  }
}
