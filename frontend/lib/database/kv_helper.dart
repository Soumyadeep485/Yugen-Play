import 'dart:convert';
import 'package:frontend/database/database.dart';
import 'package:frontend/database/isar_models/key_value.dart';
import 'package:isar_community/isar.dart';

/// Enum for keys that require a dynamic ID (like an AniList mediaId)
enum DynamicKeys {
  stickySource,
  trackBindings,
}

/// Extension to easily append the mediaId to our enums
extension DynamicKvExtensions on Enum {
  T get<T>(String suffix, [T? defaultValue]) =>
      KvHelper.get<T>('${name}_$suffix', defaultVal: defaultValue);

  void set<T>(String suffix, T value) => 
      KvHelper.set('${name}_$suffix', value);

  void delete(String suffix) => 
      KvHelper.remove('${name}_$suffix');
}

class KvHelper {
  static T get<T>(String key, {T? defaultVal}) {
    final col = isar.collection<KeyValue>();
    final result = col.filter().keyEqualTo(key).findFirstSync();

    if (result?.value == null) {
      if (defaultVal != null) return defaultVal;
      return null as T;
    }

    final dynamic val = jsonDecode(result!.value!)['val'];

    // Handle type casting explicitly from JSON
    if (val is num) {
      if (T == double) return val.toDouble() as T;
      if (T == int) return val.toInt() as T;
    }
    
    if (val is List && val.every((e) => e is String)) {
      return val.cast<String>() as T;
    }
    
    if (val is Map) return Map<String, dynamic>.from(val) as T;

    if (val is! T) {
      if (defaultVal != null) return defaultVal;
      return null as T;
    }

    return val;
  }

  static void set<T>(String key, T value) {
    final data = KeyValue()
      ..key = key
      ..value = jsonEncode({'val': value});

    isar.writeTxnSync(() {
      isar.collection<KeyValue>().putSync(data);
    });
  }

  static void remove(String key) {
    final col = isar.collection<KeyValue>();
    final data = col.filter().keyEqualTo(key).findFirstSync();

    if (data == null) return;

    isar.writeTxnSync(() {
      col.deleteSync(data.id);
    });
  }
}