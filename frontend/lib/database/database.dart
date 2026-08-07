import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/database/isar_models/key_value.dart';

late final Isar isar;

Future<void> initIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open(
    [KeyValueSchema],
    directory: dir.path,
  );
}