import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';

class TvLibraryService {
  // 🚀 FIX: Actually matching the mobile app box name now
  static const String _boxName = 'anime_library'; 

  Future<Box<String>> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return await Hive.openBox<String>(_boxName);
  }

  Future<void> addToLibrary(String animeId, String title, String posterUrl, String status) async {
    final box = await _getBox();
    
    final itemData = {
      'animeId': animeId,
      'title': title,
      'posterUrl': posterUrl,
      'status': status,
      'episodes': 0, // Fallback
      'updatedAt': DateTime.now().millisecondsSinceEpoch, // Match mobile's integer timestamp
    };

    // 🚀 FIX: Save as JSON string like the mobile app does
    await box.put(animeId, jsonEncode(itemData));
  }

  Future<void> removeFromLibrary(String animeId) async {
    final box = await _getBox();
    await box.delete(animeId);
  }
  
  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
  }
}