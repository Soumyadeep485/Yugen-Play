import 'package:isar_community/isar.dart';

part 'key_value.g.dart'; // This will be generated shortly

@collection
class KeyValue {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;

  String? value;
}