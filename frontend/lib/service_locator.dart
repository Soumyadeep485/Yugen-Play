import 'package:flutter/foundation.dart';
import 'package:frontend/features/player/controllers/player_controller.dart';
import 'package:frontend/features/player/data/extensions/extension_manager.dart';
import 'package:frontend/features/player/data/player_repository.dart';
import 'package:frontend/features/player/services/extension_updater_service.dart';
import 'package:get_it/get_it.dart';
import 'features/player/services/stream_service.dart';
import 'features/player/services/mapping_service.dart';
//import 'features/player/data/custom_provider.dart';
import 'features/player/data/registry/plugin_registry.dart';
import 'features/player/services/plugin_manager.dart';
import 'features/player/data/extensions/js_runtime_provider.dart';
import 'features/player/services/extension_service.dart';
import 'package:frontend/core/network/app_network_client.dart';
import 'package:frontend/core/network/extension_client.dart';

// This is our global instance
final locator = GetIt.instance;

void setupLocator() {
  debugPrint('   -> setupLocator: 1. Starting...');

  locator.registerLazySingleton<AppNetworkClient>(() => AppNetworkClient());
  // Extension Client injection[cite: 1]
  locator.registerLazySingleton<ExtensionClient>(
    () => ExtensionClient(locator<AppNetworkClient>()),
  );
  debugPrint('   -> setupLocator: Extension Client registered.');

  final streamService = StreamService();
  // streamService.registerProvider(CustomProvider());

  locator.registerLazySingleton<StreamService>(() => streamService);
  debugPrint('   -> setupLocator: 2. StreamService registered.');

  locator.registerLazySingleton<MappingService>(() => MappingService());
  debugPrint('   -> setupLocator: 3. MappingService registered.');

  locator.registerLazySingleton<PluginRegistry>(() => PluginRegistry());
  locator.registerLazySingleton<JsRuntimeProvider>(() => JsRuntimeProvider());
  locator.registerLazySingleton<PluginManager>(
    () => PluginManager(locator<JsRuntimeProvider>()),
  );
  debugPrint('   -> setupLocator: 4. Plugin architecture registered.');

  locator.registerLazySingleton<ExtensionService>(
    () =>
        ExtensionService(locator<ExtensionClient>(), locator<PluginRegistry>()),
  );
  debugPrint('   -> setupLocator: 5. ExtensionService registered.');

  locator.registerLazySingleton<PlayerRepository>(
    () => PlayerRepository(
      streamService: locator<StreamService>(),
      mappingService: locator<MappingService>(),
    ),
  );
  debugPrint('   -> setupLocator: 6. PlayerRepository registered.');

  locator.registerFactory<PlayerController>(
    () => PlayerController(
      repository: locator<PlayerRepository>(),
      pluginRegistry: locator<PluginRegistry>(),
      pluginManager: locator<PluginManager>(),
    ),
  );
  debugPrint('   -> setupLocator: 7. PlayerController registered. DONE.');

  locator.registerLazySingleton<ExtensionUpdaterService>(
    () => ExtensionUpdaterService(locator<ExtensionClient>()),
  );
  debugPrint('   -> setupLocator: 8. ExtensionUpdaterService registered.');

  locator.registerLazySingleton<ExtensionManager>(
    () => ExtensionManager(locator<JsRuntimeProvider>()),
  );
  debugPrint(
    '   -> setupLocator: 9. ExtensionManager runtime boundary registered.',
  );
}
