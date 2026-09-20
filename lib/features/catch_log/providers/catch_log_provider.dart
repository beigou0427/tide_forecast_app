import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/catch_log_model.dart';

final catchLogProvider = StateNotifierProvider<CatchLogNotifier, List<CatchLogItem>>((ref) {
  return CatchLogNotifier();
});

class CatchLogNotifier extends StateNotifier<List<CatchLogItem>> {
  static const String _storageKey = "catch_logs_v1";

  CatchLogNotifier() : super([]) {
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawList = prefs.getStringList(_storageKey) ?? [];
      state = rawList.map((e) => CatchLogItem.fromJson(e)).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    } catch (_) {
      state = [];
    }
  }

  Future<void> addLog(CatchLogItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = [item, ...state];
    state = updated;
    final rawList = updated.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, rawList);
  }

  Future<void> deleteLog(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = state.where((e) => e.id != id).toList();
    state = updated;
    final rawList = updated.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, rawList);
  }
}
