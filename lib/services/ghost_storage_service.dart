import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ghost_data.dart';

class GhostStorageService {
  final String _key = 'ghosts';

  Future<void> saveGhost(GhostData ghost) async {
    final prefs = await SharedPreferences.getInstance();
    final ghosts = await getAllGhosts();
    ghosts.add(ghost);

    final ghostList = ghosts.map((g) => jsonEncode(g.toJson())).toList();
    await prefs.setStringList(_key, ghostList);
  }

  Future<void> deleteGhostAt(int index) async {
  final prefs = await SharedPreferences.getInstance();
  final List<String> ghostList = prefs.getStringList('ghosts') ?? [];

  if (index >= 0 && index < ghostList.length) {
    ghostList.removeAt(index);
    await prefs.setStringList('ghosts', ghostList);
  }
}

  Future<List<GhostData>> getAllGhosts() async {
    final prefs = await SharedPreferences.getInstance();
    final ghostList = prefs.getStringList(_key) ?? [];

    return ghostList
        .map((str) => GhostData.fromJson(jsonDecode(str)))
        .toList();
  }
}
