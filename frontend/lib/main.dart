import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/storage/hive_service.dart';
import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MediaKit.ensureInitialized();
  await HiveService.initialize();

  runApp(const YugenPlayApp());
}
