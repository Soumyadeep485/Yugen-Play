import 'package:get_it/get_it.dart';

import 'core/network/anilist_client.dart';
import 'core/network/app_network_client.dart';
import 'features/extensions/services/extension_client.dart';
import 'features/home/controllers/home_controller.dart';
import 'features/home/services/home_repository.dart';
import 'features/player/controllers/player_controller.dart';
// 🛑 Import your ExtensionManager here
import 'features/player/services/extension_manager.dart';
import 'features/player/services/js_runtime_provider.dart';
import 'features/player/services/mapping_service.dart';
import 'features/player/services/player_repository.dart';
import 'features/player/services/plugin_manager.dart';
import 'features/player/services/plugin_registry.dart';
import 'features/player/services/stream_service.dart';
import 'features/search/services/search_repository.dart';

final getIt = GetIt.instance;
final locator = getIt;

void setupServiceLocator() {
  // Core Network Clients
  getIt.registerLazySingleton<AppNetworkClient>(() => AppNetworkClient());
  getIt.registerLazySingleton<AniListClient>(() => AniListClient());
  getIt.registerLazySingleton<ExtensionClient>(
    () => ExtensionClient(getIt<AppNetworkClient>()),
  );

  // Repositories
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepository(getIt<AniListClient>()),
  );
  getIt.registerLazySingleton<SearchRepository>(
    () => SearchRepository(getIt<AniListClient>()),
  );

  // Controllers
  getIt.registerFactory<HomeController>(
    () => HomeController(getIt<HomeRepository>()),
  );

  getIt.registerLazySingleton<MappingService>(
    () => MappingService(getIt<AppNetworkClient>().dio),
  );

  getIt.registerLazySingleton<PluginRegistry>(() => PluginRegistry());
  getIt.registerLazySingleton<JsRuntimeProvider>(() => JsRuntimeProvider());

  getIt.registerLazySingleton<PluginManager>(
    () => PluginManager(getIt<JsRuntimeProvider>()),
  );

  // 🛑 FIX: Register the missing ExtensionManager here
  // Note: If ExtensionManager requires parameters (like ExtensionClient), add them inside the parenthesis.
  getIt.registerLazySingleton<ExtensionManager>(() => ExtensionManager());

  getIt.registerLazySingleton<StreamService>(
    () => StreamService(getIt<ExtensionClient>()),
  );

  getIt.registerLazySingleton<PlayerRepository>(
    () => PlayerRepository(
      streamService: getIt<StreamService>(),
      mappingService: getIt<MappingService>(),
    ),
  );
  getIt.registerFactory<PlayerController>(
    () => PlayerController(
      repository: getIt<PlayerRepository>(),
      pluginRegistry: getIt<PluginRegistry>(),
      pluginManager: getIt<PluginManager>(),
    ),
  );
}
