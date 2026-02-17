import 'package:untitled1/domain/entities/track.dart';
import 'package:untitled1/domain/repositories/track_repository.dart';

class GetTracks {
  final TrackRepository repository;

  const GetTracks(this.repository);

  /// Fetches tracks via search (may be geo-blocked in some regions).
  Future<List<Track>> call({
    required String query,
    required int index,
    int limit = 50,
  }) {
    return repository.getTracks(query: query, index: index, limit: limit);
  }

  /// Fetches tracks from a Deezer playlist (works globally).
  Future<List<Track>> fromPlaylist({
    required String playlistId,
    required int index,
    int limit = 100,
  }) {
    return repository.getPlaylistTracks(
      playlistId: playlistId,
      index: index,
      limit: limit,
    );
  }
}
