import '../../extensions/services/extension_client.dart';
import 'plugin_registry.dart';

class ExtensionService {
  // ignore: unused_field
  final ExtensionClient _extensionClient;
  // ignore: unused_field
  final PluginRegistry _pluginRegistry;

  ExtensionService(this._extensionClient, this._pluginRegistry);
}
