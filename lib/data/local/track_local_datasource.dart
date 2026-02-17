import 'package:hive/hive.dart';
import 'package:untitled1/core/errors/exceptions.dart';
import 'package:untitled1/data/models/track_model.dart';
import 'package:untitled1/hive/hive_init.dart';

abstract class TrackLocalDatasource {
  /// Gets all cached tracks from Hive.
  List<TrackModel> getCachedTracks();

  /// Caches tracks to Hive. Uses track ID as key for deduplication.
  Future<void> cacheTracks(List<TrackModel> tracks);

  /// Clears the track cache.
  Future<void> clearCache();

  /// Gets the number of cached tracks.
  int get cachedTrackCount;
}

class TrackLocalDatasourceImpl implements TrackLocalDatasource {
  TrackLocalDatasourceImpl();

  Box<TrackModel> get _trackBox => HiveInit.getTrackBox();

  @override
  List<TrackModel> getCachedTracks() {
    try {
      return _trackBox.values.toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get cached tracks: $e');
    }
  }

  @override
  Future<void> cacheTracks(List<TrackModel> tracks) async {
    try {
      final Map<dynamic, TrackModel> entries = {
        for (final track in tracks) track.trackId: track,
      };
      await _trackBox.putAll(entries);
    } catch (e) {
      throw CacheException(message: 'Failed to cache tracks: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _trackBox.clear();
    } catch (e) {
      throw CacheException(message: 'Failed to clear cache: $e');
    }
  }

  @override
  int get cachedTrackCount => _trackBox.length;
}
