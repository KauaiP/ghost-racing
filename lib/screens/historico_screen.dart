import 'package:flutter/material.dart';
import 'package:myapp/screens/home_screen.dart';

class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? arguments =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final double? distance = arguments?['distance'];
    final Duration? elapsedTime = arguments?['elapsedTime'];
    final double? pace = arguments?['pace'];

    return Scaffold(
      backgroundColor: const Color(0xFFD8ECF9),
      appBar: AppBar(
        title: const Text('Resumo da Corrida'),
        backgroundColor: const Color(0xFF702C50),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Histórico de Corrida',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            if (distance != null)
              Text('Distância: ${distance.toStringAsFixed(2)} km',
                  style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            if (elapsedTime != null)
              Text('Tempo: ${_formatDuration(elapsedTime)}',
                  style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            if (pace != null)
              Text('Pace: ${pace.toStringAsFixed(2)} min/km',
                  style: const TextStyle(fontSize: 18)),
            if (distance == null && elapsedTime == null && pace == null)
              const Text('Nenhum dado de corrida disponível.'),
          ],
        ),
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF702C50),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
        child: const Text('Fechar'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
