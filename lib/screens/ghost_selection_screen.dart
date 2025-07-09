import 'package:flutter/material.dart';
import '../services/ghost_storage_service.dart';
import '../models/ghost_data.dart';
import 'map_screen.dart';

class GhostSelectionScreen extends StatefulWidget {
  const GhostSelectionScreen({super.key});

  @override
  State<GhostSelectionScreen> createState() => _GhostSelectionScreenState();
}

class _GhostSelectionScreenState extends State<GhostSelectionScreen> {
  List<GhostData> ghosts = [];

  @override
  void initState() {
    super.initState();
    _loadGhosts();
  }

  Future<void> _loadGhosts() async {
    ghosts = await GhostStorageService().getAllGhosts();
    setState(() {});
  }

  void _startRaceWithGhost(GhostData ghost) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(ghost: ghost),
      ),
    );
  }

  void _startRaceWithoutGhost() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MapScreen(),
      ),
    );
  }

  Future<void> _deleteGhost(int index) async {
    final service = GhostStorageService();
    await service.deleteGhostAt(index); // Você precisa implementar isso
    await _loadGhosts(); // Atualiza a tela
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3CDD1),
      appBar: AppBar(
        title: const Text('Escolha um Fantasma'),
        backgroundColor: const Color(0xFF702C50),
      ),
      body: ghosts.isEmpty
          ? Center(
              child: ElevatedButton(
                onPressed: _startRaceWithoutGhost,
                child: const Text('Correr sem fantasma'),
              ),
            )
          : ListView.builder(
              itemCount: ghosts.length,
              itemBuilder: (context, index) {
                final ghost = ghosts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      'Fantasma ${index + 1} - ${(ghost.distance / 1000).toStringAsFixed(2)} km',
                    ),
                    subtitle: Text(
                      'Tempo: ${ghost.elapsedSeconds}s • Pace: ${ghost.pace.toStringAsFixed(2)} min/km',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteGhost(index),
                    ),
                    onTap: () => _startRaceWithGhost(ghost),
                  ),
                );
              },
            ),
      floatingActionButton: ElevatedButton(
        onPressed: _startRaceWithoutGhost,
        child: const Text('Correr sem fantasma'),
      ),
    );
  }
}
