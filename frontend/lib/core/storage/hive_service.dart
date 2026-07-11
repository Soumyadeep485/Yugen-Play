import 'package:hive_ce_flutter/hive_flutter.dart';

import 'boxes.dart';

class HiveService {
  HiveService._();

  static Future<void> initialize() async {
    await Hive.initFlutter();

    await Hive.openBox<String>(HiveBoxes.searchHistory);

    await Hive.openBox<int>(HiveBoxes.favorites);

    await Hive.openBox(HiveBoxes.continueWatching);

    await Hive.openBox(HiveBoxes.settings);

    await Hive.openBox(HiveBoxes.downloads);

    await Hive.openBox(HiveBoxes.user);
  }
}
