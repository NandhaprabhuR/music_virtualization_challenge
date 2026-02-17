import 'package:untitled1/domain/entities/lyrics.dart';

abstract class LyricsRepository {
  /// Fetches lyrics for a track using LRCLIB cached endpoint.
  Future<Lyrics> getLyrics({
    required String trackName,
    required String artistName,
    required String albumName,
    required int duration,
  });
}
