import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/storage/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.initialize();

  runApp(const YugenPlayApp());
}
