import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';

class SearchHistoryService {
  final Box<String> _box = Hive.box<String>('search_history');

  List<String> getHistory() {
    final data = _box.get('history');
    if (data == null) return [];
    return List<String>.from(jsonDecode(data));
  }

  Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final history = getHistory();
    history.remove(trimmed); // Remove it if it exists so we can move it to the top
    history.insert(0, trimmed);
    
    if (history.length > 10) {
      history.removeLast(); // Cap it at 10 recent searches
    }
    
    await _box.put('history', jsonEncode(history));
  }

  Future<void> removeSearch(String query) async {
    final history = getHistory();
    history.remove(query);
    await _box.put('history', jsonEncode(history));
  }

  Future<void> clearAll() async {
    await _box.put('history', jsonEncode([]));
  }
}