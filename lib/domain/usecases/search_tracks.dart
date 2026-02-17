import 'package:untitled1/domain/entities/track.dart';
import 'package:untitled1/domain/repositories/track_repository.dart';

class SearchTracks {
  final TrackRepository repository;

  const SearchTracks(this.repository);

  /// Searches for tracks matching [query]. Returns first page of results.
  /// For search, we always start from index 0 and can paginate further.
  Future<List<Track>> call({
    required String query,
    int index = 0,
    int limit = 50,
  }) {
    return repository.getTracks(query: query, index: index, limit: limit);
  }
}
