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

  Future<List<GhostData>> getAllGhosts() async {
    final prefs = await SharedPreferences.getInstance();
    final ghostList = prefs.getStringList(_key) ?? [];

    return ghostList
        .map((str) => GhostData.fromJson(jsonDecode(str)))
        .toList();
  }
}
