import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../service_locator.dart';
import '../models/home_data.dart';
import '../services/home_repository.dart';

/// Immutable state container for Home feature
class HomeState {
  final HomeData data;
  final bool isLoading;
  final String? error;

  const HomeState({required this.data, required this.isLoading, this.error});

  factory HomeState.initial() =>
      HomeState(data: HomeData.empty(), isLoading: true);

  HomeState copyWith({HomeData? data, bool? isLoading, String? error}) {
    return HomeState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Global Riverpod Provider
final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);

/// Home State Notifier
class HomeNotifier extends Notifier<HomeState> {
  late final HomeRepository _repository;

  @override
  HomeState build() {
    _repository = locator<HomeRepository>();
    // Trigger initial fetch asynchronously after build
    Future.microtask(() => fetchHomeData());
    return HomeState.initial();
  }

  Future<void> fetchHomeData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final homeData = await _repository.fetchHomeData();
      state = state.copyWith(data: homeData, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
