import 'dart:async';

class MockEpisode {
  final String id;
  final int number;

  const MockEpisode({required this.id, required this.number});
}

class DebugPluginHarness {
  // Simulates JavaScript compilation and DOM scraping delays safely off the UI thread
  Future<List<MockEpisode>> simulateJsScraperExecution(
    String pluginName,
    int anilistId,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 1500),
    ); // Simulates network/JS compilation latency

    if (pluginName.contains('Broken') || anilistId == 404) {
      throw Exception(
        "JS Sandbox Runtime Exception: Failed to execute evaluate() on window context.",
      );
    }

    // Returns structural mock data formatted exactly like your engine expects
    return List.generate(
      24,
      (index) => MockEpisode(
        id: 'stream_ep_${index + 1}_source_$pluginName',
        number: index + 1,
      ),
    );
  }
}
