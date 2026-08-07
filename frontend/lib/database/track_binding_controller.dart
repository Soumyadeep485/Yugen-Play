import 'dart:convert';
import 'package:frontend/database/kv_helper.dart';
import 'package:frontend/database/track_binding.dart';

class TrackBindingController {
  final Map<String, List<TrackBinding>> _cache = {};

  /// Retrieves stored tracker bindings for a specific anime ID
  List<TrackBinding> getBindingsFor(String mediaId) {
    if (_cache.containsKey(mediaId)) {
      return List.unmodifiable(_cache[mediaId]!);
    }
    
    final raw = DynamicKeys.trackBindings.get<String>(mediaId, '[]');
    final list = <TrackBinding>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      for (final entry in decoded) {
        if (entry is Map) {
          list.add(TrackBinding.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
    } catch (e) {
      print('TrackBinding decode failed for $mediaId: $e');
    }
    
    _cache[mediaId] = list;
    return List.unmodifiable(list);
  }

  bool hasAnyBinding(String mediaId) => getBindingsFor(mediaId).isNotEmpty;

  /// Binds or updates a tracker link for an anime
  Future<void> bind(String mediaId, TrackBinding binding) async {
    final list = getBindingsFor(mediaId)
        .where((b) => b.trackerId != binding.trackerId)
        .toList();
    list.add(binding);
    _cache[mediaId] = list;
    _persist(mediaId, list);
  }

  /// Removes a specific tracker binding
  Future<void> unbind(String mediaId, int trackerId) async {
    final list =
        getBindingsFor(mediaId).where((b) => b.trackerId != trackerId).toList();
    _cache[mediaId] = list;
    _persist(mediaId, list);
  }

  void _persist(String mediaId, List<TrackBinding> list) {
    DynamicKeys.trackBindings.set<String>(
      mediaId,
      jsonEncode(list.map((b) => b.toJson()).toList()),
    );
  }

  /// Synchronizes watch progress concurrently across all bound platforms
  Future<void> pushProgress(
    String mediaId,
    int progress, {
    required bool isAnime,
    String? status,
    required Future<void> Function(Tracker tracker, String remoteId, int progress, String status) updateRemote,
  }) async {
    final bindings = getBindingsFor(mediaId);
    if (bindings.isEmpty) return;

    // Run remote list updates in parallel
    await Future.wait(bindings.map((b) async {
      final currentStatus = status ?? b.status;
      try {
        await updateRemote(b.tracker, b.remoteId, progress, currentStatus);
        b.progress = progress;
        if (status != null) b.status = status;
      } catch (e) {
        print('Track sync failed for ${b.tracker.label} ($mediaId): $e');
      }
    }));

    _persist(mediaId, bindings);
  }
}