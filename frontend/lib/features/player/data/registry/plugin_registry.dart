import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import '../../models/plugin_meta.dart';

class PluginRegistry {
  static const String _boxName = 'plugin_registry_box';
  late Box _box;

  // 1. Initialize the Database
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);

    // Fallback: If the database is completely empty, insert the demo plugin automatically
    if (_box.isEmpty) {
      debugPrint('⚠️ Hive box empty. Injecting Demo Plugin fallback.');
      final demoPlugin = PluginMeta(
        id: 'demo_provider',
        name: 'Demo Provider',
        version: '1.0.0',
        path: 'assets/extensions/demo.js',
        enabled: true,
      );
      await savePlugin(demoPlugin);
    }
  }

  // 2. Retrieve ALL plugins (used by Settings UI)
  List<PluginMeta> getInstalledPlugins() {
    final List<PluginMeta> plugins = [];

    for (var key in _box.keys) {
      final map = _box.get(key) as Map<dynamic, dynamic>;
      plugins.add(PluginMeta.fromMap(map));
    }

    return plugins;
  }

  // 3. Retrieve ONLY active plugins (used by the PlayerController & Watch Tab)
  Future<List<PluginMeta>> getActivePlugins() async {
    final plugins = getInstalledPlugins();
    return plugins.where((p) => p.enabled).toList();
  }

  // 4. Check toggle state using the plugin ID
  bool isPluginActive(String id) {
    final map = _box.get(id) as Map<dynamic, dynamic>?;
    if (map != null) {
      return map['enabled'] == true;
    }
    return false;
  }

  // 5. Save or Update a plugin
  Future<void> savePlugin(PluginMeta plugin) async {
    await _box.put(plugin.id, plugin.toMap());
    debugPrint('💾 Saved plugin to Hive: ${plugin.name}');
  }

  // 6. Writes the new toggle state directly to the plugin map
  Future<void> togglePlugin(String id, bool isActive) async {
    final map = _box.get(id) as Map<dynamic, dynamic>?;
    if (map != null) {
      map['enabled'] = isActive; // Updates the enabled state
      await _box.put(id, map);
      debugPrint('🔄 Toggled plugin $id to $isActive');
    }
  }

  // 7. Delete a plugin
  Future<void> removePlugin(String id) async {
    await _box.delete(id);
    debugPrint('🗑️ Removed plugin from Hive: $id');
  }
}
