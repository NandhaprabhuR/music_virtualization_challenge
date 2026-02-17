import 'package:untitled1/domain/entities/lyrics.dart';

class LyricsModel extends Lyrics {
  const LyricsModel({
    required super.id,
    required super.trackName,
    required super.artistName,
    required super.albumName,
    required super.duration,
    required super.plainLyrics,
    required super.syncedLyrics,
  });

  factory LyricsModel.fromJson(Map<String, dynamic> json) {
    return LyricsModel(
      id: json['id'] as int? ?? 0,
      trackName: json['trackName'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      albumName: json['albumName'] as String? ?? '',
      duration: (json['duration'] is num)
          ? (json['duration'] as num).toDouble()
          : 0.0,
      plainLyrics: json['plainLyrics'] as String? ?? '',
      syncedLyrics: json['syncedLyrics'] as String? ?? '',
    );
  }
}
