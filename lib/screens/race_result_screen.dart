import 'package:flutter/material.dart';

class RaceResultScreen extends StatelessWidget {
  final double userDistance;
  final int userTime;
  final double userPace;
  final double ghostDistance;
  final int ghostTime;
  final double ghostPace;
  final bool userWon;

  const RaceResultScreen({
    super.key,
    required this.userDistance,
    required this.userTime,
    required this.userPace,
    required this.ghostDistance,
    required this.ghostTime,
    required this.ghostPace,
    required this.userWon,
  });

  @override
  Widget build(BuildContext context) {
    String formatTime(int seconds) {
      final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
      final secs = (seconds % 60).toString().padLeft(2, '0');
      return '$minutes:$secs';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado da Corrida'),
        backgroundColor: const Color(0xFF702C50),
      ),
      backgroundColor: const Color(0xFFB3CDD1),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              userWon ? 'Parabéns! Você venceu!' : 'O fantasma venceu!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF702C50),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildStatBlock('Você', userDistance, userTime, userPace, Colors.blue),
            const SizedBox(height: 20),
            _buildStatBlock('Fantasma', ghostDistance, ghostTime, ghostPace, Colors.purple),
          ],
        ),
      ),
    );
  }

  String formatTime(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$remainingSeconds';
}

  Widget _buildStatBlock(String title, double distance, int time, double pace, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text('Distância: ${distance.toStringAsFixed(2)} metros'),
          Text('Tempo: ${formatTime(time)}'),
          Text('Pace: ${pace.toStringAsFixed(2)} min/km'),
        ],
      ),
    );
  }
}
