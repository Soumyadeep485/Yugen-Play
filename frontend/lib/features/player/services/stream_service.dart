import 'dart:collection';

import '../data/streaming_provider.dart';

/// Central registry for all streaming providers.
///
/// The service is responsible for:
///
/// - Registering providers
/// - Unregistering providers
/// - Selecting the active provider
/// - Looking up providers
///
/// It intentionally contains **no streaming logic**.
///
/// All episode, server and stream fetching belongs to
/// [PlayerRepository].
///
/// This separation keeps provider management isolated from
/// business logic.
class StreamService {
  StreamService();

  final Map<String, StreamingProvider> _providers = {};

  StreamingProvider? _currentProvider;

  /// Returns every registered provider.
  ///
  /// The returned collection cannot be modified externally.
  UnmodifiableMapView<String, StreamingProvider> get providers =>
      UnmodifiableMapView(_providers);

  /// Returns the currently selected provider.
  StreamingProvider? get currentProvider => _currentProvider;

  /// Whether an active provider has been selected.
  bool get hasCurrentProvider => _currentProvider != null;

  /// Number of registered providers.
  int get providerCount => _providers.length;

  /// Registers a provider.
  ///
  /// If another provider with the same name already exists,
  /// it will be replaced.
  ///
  /// The first registered provider automatically becomes the
  /// current provider.
  void registerProvider(StreamingProvider provider) {
    _providers[provider.name] = provider;

    _currentProvider ??= provider;
  }

  /// Registers multiple providers.
  void registerProviders(Iterable<StreamingProvider> providers) {
    for (final provider in providers) {
      registerProvider(provider);
    }
  }

  /// Removes a provider.
  ///
  /// Returns true if the provider existed.
  bool unregisterProvider(String providerName) {
    final removed = _providers.remove(providerName);

    if (removed == null) {
      return false;
    }

    if (_currentProvider == removed) {
      _currentProvider = _providers.isEmpty ? null : _providers.values.first;
    }

    return true;
  }

  /// Returns whether a provider exists.
  bool hasProvider(String providerName) {
    return _providers.containsKey(providerName);
  }

  /// Returns a provider by name.
  ///
  /// Returns null if it doesn't exist.
  StreamingProvider? getProvider(String providerName) {
    return _providers[providerName];
  }

  /// Sets the active provider.
  ///
  /// Throws a [StateError] if the provider
  /// has not been registered.
  void setCurrentProvider(String providerName) {
    final provider = _providers[providerName];

    if (provider == null) {
      throw StateError('Provider "$providerName" is not registered.');
    }

    _currentProvider = provider;
  }

  /// Removes every registered provider.
  void clear() {
    _providers.clear();
    _currentProvider = null;
  }

  @override
  String toString() {
    return 'StreamService('
        'providers: ${_providers.length}, '
        'currentProvider: ${_currentProvider?.name}'
        ')';
  }
}
