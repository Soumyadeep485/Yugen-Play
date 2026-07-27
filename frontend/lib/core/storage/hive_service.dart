import 'package:hive_ce_flutter/hive_flutter.dart';

class HiveService {
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Box for storing JSON strings of watch history
    await Hive.openBox<String>('watch_history');

    // We can open the search history box now too while we're here
    await Hive.openBox<String>('search_history');

    await Hive.openBox<String>('anime_library');
  }
}
