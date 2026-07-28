import 'package:hive_ce_flutter/hive_flutter.dart';
import 'hive_boxes.dart'; // Ensure you import your constants

class HiveService {
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Use the constants strictly
    await Hive.openBox<String>(HiveBoxes.continueWatching);
    await Hive.openBox<String>(HiveBoxes.searchHistory);
    await Hive.openBox<String>(HiveBoxes.animeLibrary);
  }
}