import 'package:untitled1/domain/entities/track.dart';
import 'package:untitled1/domain/entities/track_detail.dart';

abstract class TrackRepository {
  /// Fetches a page of tracks using the given [query] and [index] offset.
  Future<List<Track>> getTracks({
    required String query,
    required int index,
    int limit = 50,
  });

  /// Fetches tracks from a Deezer playlist.
  Future<List<Track>> getPlaylistTracks({
    required String playlistId,
    required int index,
    int limit = 100,
  });

  /// Fetches full track details by [trackId].
  Future<TrackDetail> getTrackDetails({required int trackId});

  /// Gets cached tracks from local storage.
  Future<List<Track>> getCachedTracks();

  /// Caches a list of tracks to local storage.
  Future<void> cacheTracks(List<Track> tracks);
}
