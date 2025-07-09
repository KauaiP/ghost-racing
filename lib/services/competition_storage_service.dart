
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/competition_result.dart';

class CompetitionStorageService {
  static const String _key = 'competition_results';

  Future<void> saveResult(CompetitionResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    existing.add(jsonEncode(result.toJson()));
    await prefs.setStringList(_key, existing);
  }

  Future<List<CompetitionResult>> getAllResults() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data
        .map((e) => CompetitionResult.fromJson(jsonDecode(e)))
        .toList();
  }

  Future<void> clearResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
