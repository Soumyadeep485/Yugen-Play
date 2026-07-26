import '../../extensions/services/extension_client.dart';
import 'streaming_provider.dart';

class StreamService {
  // ignore: unused_field
  final ExtensionClient _extensionClient;

  /// Holds the currently active streaming provider instance.
  StreamingProvider? currentProvider;

  StreamService(this._extensionClient);
}
