import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const GhostRaceApp());
}

class GhostRaceApp extends StatelessWidget {
  const GhostRaceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghost Race',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFD8ECF9),
        primaryColor: const Color(0xFF4FC3F7),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB36D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4FC3F7),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
      home: const StartScreen(),
    );
  }
}

class StartScreen extends StatefulWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool isRunning = false;
  String distance = '0.00 km';
  String time = '00:00';
  String pace = '--:-- /km';
  late Timer _timer;
  int _seconds = 0;
  double _distanceValue = 0.0;

  void _startTimer() {
    setState(() {
      isRunning = true;
    });
    _seconds = 0;
    _distanceValue = 0.0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        time = _formatTime(_seconds);
        _distanceValue += 0.01;
        distance = '${_distanceValue.toStringAsFixed(2)} km';
        pace = _calculatePace(_seconds, _distanceValue);
      });
    });
  }

  String _formatTime(int seconds) {
    int minutes = (seconds / 60).truncate();
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _calculatePace(int seconds, double distance) {
    if (distance == 0) return '--:-- /km';
    double paceMinutesPerKm = (seconds / distance) / 60;
    int paceMinutes = paceMinutesPerKm.truncate();
    double paceSecondsPerKm = (paceMinutesPerKm - paceMinutes) * 60;
    return '${paceMinutes.toString().padLeft(2, '0')}:${paceSecondsPerKm.toStringAsFixed(0).padLeft(2, '0')} /km';
  }

  void _stopTimer() {
    setState(() {
      isRunning = false;
    });
    _timer.cancel();
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      distance = '0.00 km';
      time = '00:00';
      pace = '--:-- /km';
      _seconds = 0;
      _distanceValue = 0.0;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Icon(icon, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('GhostStride'),
        leading: IconButton(
          icon: const Icon(Icons.directions_run),
          onPressed: () {},
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 300,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Column(
                children: [
                  _buildStatCard("Distance", distance, Icons.location_on),
                  _buildStatCard("Time", time, Icons.access_time),
                  _buildStatCard("Pace", pace, Icons.speed),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isRunning ? _stopTimer : _startTimer,
              child: Text(isRunning ? 'Stop Race' : 'Start Race'),
            ),
            if (!isRunning && _seconds > 0)
              TextButton(
                onPressed: _resetTimer,
                child: const Text("Reset"),
              ),
          ],
        ),
      ),
    );
  }
}