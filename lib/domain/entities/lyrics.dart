import 'package:equatable/equatable.dart';

class Lyrics extends Equatable {
  final int id;
  final String trackName;
  final String artistName;
  final String albumName;
  final double duration;
  final String plainLyrics;
  final String syncedLyrics;

  const Lyrics({
    required this.id,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    required this.duration,
    required this.plainLyrics,
    required this.syncedLyrics,
  });

  bool get hasLyrics => plainLyrics.isNotEmpty || syncedLyrics.isNotEmpty;

  /// Returns the best available lyrics (prefers synced, falls back to plain)
  String get displayLyrics {
    if (syncedLyrics.isNotEmpty) return syncedLyrics;
    if (plainLyrics.isNotEmpty) return plainLyrics;
    return 'No lyrics available';
  }

  @override
  List<Object?> get props => [id, trackName, artistName];
}
