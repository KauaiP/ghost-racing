import 'package:flutter/material.dart';
import '../models/ghost_data.dart';
import '../services/ghost_storage_service.dart';
import 'map_screen.dart';

class GhostSelectionScreen extends StatefulWidget {
  const GhostSelectionScreen({super.key});

  @override
  State<GhostSelectionScreen> createState() => _GhostSelectionScreenState();
}

class _GhostSelectionScreenState extends State<GhostSelectionScreen> {
  List<GhostData> _ghosts = [];

  @override
  void initState() {
    super.initState();
    _loadGhosts();
  }

  Future<void> _loadGhosts() async {
    final ghosts = await GhostStorageService().getAllGhosts();
    setState(() {
      _ghosts = ghosts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3CDD1),
      appBar: AppBar(
        title: const Text('Escolha um Fantasma'),
        backgroundColor: const Color(0xFF702C50),
      ),
      body: _ghosts.isEmpty
          ? const Center(
              child: Text(
                'Nenhum fantasma disponível.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _ghosts.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final ghost = _ghosts[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text('Fantasma ${index + 1}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Distância: ${(ghost.distance / 1000).toStringAsFixed(2)} km'),
                        Text('Tempo: ${_formatDuration(Duration(seconds: ghost.elapsedSeconds))}'),
                        Text('Pace: ${ghost.pace.toStringAsFixed(2)} min/km'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MapScreen(ghost: ghost),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF85324C),
                      ),
                      child: const Text('Competir'),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}
