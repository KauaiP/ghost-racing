import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ghost_data.dart';
import '../services/ghost_storage_service.dart';
import '../services/mqtt_service.dart';
import 'dart:convert';

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

  // MQTT
  MQTTService? _mqtt;
  String mqttTopic = "ghoststride/demo";

  LatLng? ghostPosition;

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
        _updateGhostPosition();
      }
    });
  }

  void _updateGhostPosition() {
    if (widget.ghost == null || _route.length < 2) return;

    final double ghostSpeed = widget.ghost!.distance / widget.ghost!.elapsedSeconds;
    final double ghostDistance = ghostSpeed * _elapsedTime.inSeconds;

    double accumulated = 0.0;
    for (int i = 0; i < _route.length - 1; i++) {
      final double segment = Geolocator.distanceBetween(
        _route[i].latitude,
        _route[i].longitude,
        _route[i + 1].latitude,
        _route[i + 1].longitude,
      );

      if (accumulated + segment >= ghostDistance) {
        final double ratio = (ghostDistance - accumulated) / segment;
        final double lat = _route[i].latitude +
            ( _route[i + 1].latitude - _route[i].latitude ) * ratio;
        final double lng = _route[i].longitude +
            ( _route[i + 1].longitude - _route[i].longitude ) * ratio;

        setState(() {
          ghostPosition = LatLng(lat, lng);
        });
        break;
      }

      accumulated += segment;
    }
  }

  void _handleIncomingMessage(String payload) {
  final data = jsonDecode(payload); // ← transforma o JSON de volta em Map
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
    final double finalPace =
        finalDistance > 0
            ? (finalElapsedTime.inSeconds / 60) / (finalDistance / 1000)
            : 0.0;

    final ghostStorage = GhostStorageService();
    final ghosts = await ghostStorage.getAllGhosts();

    if (ghosts.isEmpty) {
      await ghostStorage.saveGhost(
        GhostData(
          distance: finalDistance,
          elapsedSeconds: finalElapsedTime.inSeconds,
          pace: finalPace,
        ),
      );
    }

    Navigator.pushNamed(
      context,
      '/historico',
      arguments: {
        'distance': finalDistance,
        'elapsedTime': finalElapsedTime,
        'pace': finalPace,
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
                    if (ghostPosition != null)
                      Marker(
                        markerId: const MarkerId('ghost'),
                        position: ghostPosition!,
                        infoWindow: const InfoWindow(title: 'Fantasma'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                      ),
                  },
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Distância total:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_totalDistance.toStringAsFixed(2)} metros',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFF702C50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tempo total:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_elapsedTime.inMinutes.toString().padLeft(2, '0')}:${(_elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFF702C50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Pace:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _totalDistance > 0 && _elapsedTime.inSeconds > 0
                              ? '${((_elapsedTime.inSeconds / 60) / (_totalDistance / 1000)).toStringAsFixed(2)} min/km'
                              : 'N/A',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFF702C50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_raceState == RaceState.running)
                              ElevatedButton(
                                onPressed: _pauseRace,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                child: const Text('Pausar'),
                              ),
                            if (_raceState == RaceState.paused)
                              ElevatedButton(
                                onPressed: _resumeRace,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Retomar'),
                              ),
                            if (_raceState != RaceState.stopped)
                              ElevatedButton(
                                onPressed: _stopRace,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Encerrar'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
