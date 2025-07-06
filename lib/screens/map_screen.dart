import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

// Enum to represent the race state
enum RaceState { running, paused, stopped }

class MapScreen extends StatefulWidget {
  // RaceState enum is defined outside and accessible directly or via the state
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  RaceState _raceState =
      RaceState
          .running; // Initialize to running, correctly referencing the enum
  Position? _currentPosition;
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  List<LatLng> _route = [];
  double _totalDistance = 0.0;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _startTime = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });
      }
    });
  }

  void _stopRace() {
    _timer?.cancel();
    setState(() {
      _raceState = RaceState.stopped;
    });
    _positionStream?.cancel();

    // Collect the final race data
    final double finalDistance = _totalDistance;
    final Duration finalElapsedTime = _elapsedTime;
    // Calculate final pace: (elapsed time in minutes) / (total distance in km)
    final double finalPace = finalDistance > 0 ? (finalElapsedTime.inSeconds / 60) / (finalDistance / 1000) : 0.0;

    Navigator.pushNamed(context, '/historico', arguments: {
      'distance': finalDistance,
      'elapsedTime': finalElapsedTime,
      'pace': finalPace,
    });
  }

  void _pauseRace() {
    _timer?.cancel();
    _positionStream?.cancel();
    // The current _elapsedTime holds the time elapsed until this point
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
    _raceState =
        RaceState.running; // Ensure state is running when tracking starts
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

      if (_totalDistance > 0 && _elapsedTime.inSeconds > 0) {
        // You can calculate and store pace here if needed, though displaying it below is sufficient.
      }
    });
  }

  Future<bool> _handlePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corrida'),

        backgroundColor: const Color(0xFF702C50),
      ),
      body:
          _currentPosition == null
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
                          infoWindow: const InfoWindow(title: 'Agora'),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
