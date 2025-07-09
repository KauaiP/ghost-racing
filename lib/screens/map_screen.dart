import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ghost_data.dart';
import '../services/ghost_storage_service.dart';
import '../services/mqtt_service.dart';

bool _userWon = false;
bool _ghostWon = false;
bool _victoryNotified = false;

enum RaceState { running, paused, stopped }

class MapScreen extends StatefulWidget {
  final GhostData? ghost;
  const MapScreen({super.key, this.ghost});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  RaceState _raceState = RaceState.running;
  Position? _currentPosition;
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  List<LatLng> _route = [];
  double _totalDistance = 0.0;
  StreamSubscription<Position>? _positionStream;

  MQTTService? _mqtt;
  String mqttTopic = "ghoststride/demo";

  double _userProgress = 0.0;
  double _ghostProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _startTime = DateTime.now();
    _startTimer();

    _mqtt = MQTTService(
      clientId: 'user_${DateTime.now().millisecondsSinceEpoch}',
      topic: mqttTopic,
    );
    _mqtt!.onMessage = _handleIncomingMessage;
    _mqtt!.connect();
  }

  void _startTimer() {
  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (_startTime != null) {
      setState(() {
        _elapsedTime = DateTime.now().difference(_startTime!);
      });
      _updateGhostProgress();
      _checkVictory();
    }
  });
}

void _checkVictory() {
  if (_victoryNotified || widget.ghost == null) return;

  final ghostTotalDistance = widget.ghost!.distance;
  final ghostTotalTime = widget.ghost!.elapsedSeconds.toDouble();

  final userDone = _totalDistance >= ghostTotalDistance;
  final ghostDone = _elapsedTime.inSeconds >= ghostTotalTime;

  if (userDone && !ghostDone) {
    _victoryNotified = true;
    _userWon = true;
    _ghostWon = false;
    _showVictorySnackBar("Você venceu o fantasma!");
  } else if (ghostDone && !userDone) {
    _victoryNotified = true;
    _ghostWon = true;
    _userWon = false;
    _showVictorySnackBar("O fantasma venceu você!");
  } else if (userDone && ghostDone) {
    _victoryNotified = true;
    final userTime = _elapsedTime.inSeconds;
    final ghostTime = widget.ghost!.elapsedSeconds;

    if (userTime < ghostTime) {
      _userWon = true;
      _ghostWon = false;
      _showVictorySnackBar("Você venceu por tempo!");
    } else if (userTime > ghostTime) {
      _ghostWon = true;
      _userWon = false;
      _showVictorySnackBar("O fantasma venceu por tempo!");
    } else {
      _ghostWon = false;
      _userWon = false;
      _showVictorySnackBar("Empate!");
    }
  }
}

void _showVictorySnackBar(String message) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
      backgroundColor: Colors.indigo,
    ),
  );
}


  void _updateGhostProgress() {
    if (widget.ghost == null) return;

    final ghostTotalDistance = widget.ghost!.distance;
    final ghostTotalTime = widget.ghost!.elapsedSeconds.toDouble();

    setState(() {
      _userProgress = (_totalDistance / ghostTotalDistance).clamp(0.0, 1.0);
      _ghostProgress = (_elapsedTime.inSeconds / ghostTotalTime).clamp(0.0, 1.0);
    });
  }

  void _handleIncomingMessage(String payload) {
    final data = jsonDecode(payload);
    final ghostDistance = double.tryParse(data['distance']);
    final ghostTime = int.tryParse(data['time'].toString());

    print('Fantasma percorreu $ghostDistance metros em $ghostTime segundos');
  }

  void _stopRace() async {
  _timer?.cancel();
  _positionStream?.cancel();
  setState(() => _raceState = RaceState.stopped);

  final double finalDistance = _totalDistance;
  final Duration finalElapsedTime = _elapsedTime;
  final double finalPace = finalDistance > 0
      ? (finalElapsedTime.inSeconds / 60) / (finalDistance / 1000)
      : 0.0;

  // Salva apenas se não havia fantasma (corrida normal)
  if (widget.ghost == null) {
    final ghostStorage = GhostStorageService();
    await ghostStorage.saveGhost(
      GhostData(
        distance: finalDistance,
        elapsedSeconds: finalElapsedTime.inSeconds,
        pace: finalPace,
      ),
    );
  }

  // Define o resultado da corrida
  String? vencedor;
  if (widget.ghost != null) {
    final userWon = _totalDistance >= widget.ghost!.distance &&
        _elapsedTime.inSeconds <= widget.ghost!.elapsedSeconds;
    vencedor = userWon ? "Você venceu!" : "Fantasma venceu!";
  }

  Navigator.pushNamed(
    context,
    '/resultado_corrida', // ajuste de acordo com sua rota
    arguments: {
      'distance': finalDistance,
      'elapsedTime': finalElapsedTime,
      'pace': finalPace,
      'vencedor': vencedor,
      'ghost': widget.ghost,
    },
  );
}


  void _pauseRace() {
    _timer?.cancel();
    _positionStream?.cancel();
    setState(() {
      _raceState = RaceState.paused;
    });
  }

  void _resumeRace() {
    _startTimer();
    _startTracking();
    setState(() {
      _raceState = RaceState.running;
    });
  }

  Future<void> _initializeLocation() async {
    final hasPermission = await _handlePermission();
    if (!hasPermission) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _route.add(LatLng(position.latitude, position.longitude));
      });

      _startTracking();
    } catch (e) {
      print('Erro ao obter posição inicial: $e');
    }
  }

  void _startTracking() {
    _raceState = RaceState.running;
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (!mounted) return;

      final newPoint = LatLng(position.latitude, position.longitude);
      if (_route.isNotEmpty) {
        _totalDistance += Geolocator.distanceBetween(
          _route.last.latitude,
          _route.last.longitude,
          newPoint.latitude,
          newPoint.longitude,
        );
      }

      setState(() {
        _currentPosition = position;
        _route.add(newPoint);
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(newPoint));

      final ghostData = {
        'distance': _totalDistance.toStringAsFixed(2),
        'time': _elapsedTime.inSeconds,
      };
      _mqtt?.publish(jsonEncode(ghostData));
    });
  }

  Future<bool> _handlePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    _mqtt?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corrida'),
        backgroundColor: const Color(0xFF702C50),
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 16,
                  ),
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId("route"),
                      points: _route,
                      color: Colors.purple,
                      width: 6,
                    ),
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('start'),
                      position: _route.first,
                      infoWindow: const InfoWindow(title: 'Início'),
                    ),
                    if (_route.length > 1)
                      Marker(
                        markerId: const MarkerId('current'),
                        position: _route.last,
                        infoWindow: const InfoWindow(title: 'Você'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      ),
                  },
                ),

                if (widget.ghost != null)
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        const Text("Progresso da Corrida", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        _buildProgressRow("Você", _userProgress, Colors.blue),
                        const SizedBox(height: 4),
                        _buildProgressRow("Fantasma", _ghostProgress, Colors.purple),
                      ],
                    ),
                  ),

                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _buildStatsBox(),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressRow(String label, double progress, Color color) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label)),
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            color: color,
            minHeight: 10,
          ),
        ),
        const SizedBox(width: 10),
        Text("${(progress * 100).toStringAsFixed(0)}%"),
      ],
    );
  }

  Widget _buildStatsBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Distância total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('${_totalDistance.toStringAsFixed(2)} metros',
              style: const TextStyle(fontSize: 20, color: Color(0xFF702C50), fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Tempo total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('${_elapsedTime.inMinutes.toString().padLeft(2, '0')}:${(_elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 20, color: Color(0xFF702C50), fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Pace:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            _totalDistance > 0 && _elapsedTime.inSeconds > 0
                ? '${((_elapsedTime.inSeconds / 60) / (_totalDistance / 1000)).toStringAsFixed(2)} min/km'
                : 'N/A',
            style: const TextStyle(fontSize: 20, color: Color(0xFF702C50), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_raceState == RaceState.running)
                ElevatedButton(
                  onPressed: _pauseRace,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Pausar'),
                ),
              if (_raceState == RaceState.paused)
                ElevatedButton(
                  onPressed: _resumeRace,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Retomar'),
                ),
              if (_raceState != RaceState.stopped)
                ElevatedButton(
                  onPressed: _stopRace,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Encerrar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
