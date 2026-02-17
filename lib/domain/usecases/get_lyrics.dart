import 'package:untitled1/domain/entities/lyrics.dart';
import 'package:untitled1/domain/repositories/lyrics_repository.dart';

class GetLyrics {
  final LyricsRepository repository;

  const GetLyrics(this.repository);

  Future<Lyrics> call({
    required String trackName,
    required String artistName,
    required String albumName,
    required int duration,
  }) {
    return repository.getLyrics(
      trackName: trackName,
      artistName: artistName,
      albumName: albumName,
      duration: duration,
    );
  }
}
