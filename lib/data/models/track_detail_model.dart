import 'package:untitled1/domain/entities/track_detail.dart';

class TrackDetailModel extends TrackDetail {
  const TrackDetailModel({
    required super.id,
    required super.title,
    required super.artistName,
    required super.artistId,
    required super.albumTitle,
    required super.albumId,
    required super.albumCoverSmall,
    required super.albumCoverMedium,
    required super.albumCoverBig,
    required super.albumCoverXl,
    required super.duration,
    required super.rank,
    required super.releaseDate,
    required super.explicitLyrics,
    required super.preview,
    required super.bpm,
    required super.gain,
    required super.diskNumber,
    required super.trackPosition,
    required super.contributors,
  });

  factory TrackDetailModel.fromJson(Map<String, dynamic> json) {
    // Parse contributors list
    final contributorsList = <String>[];
    if (json['contributors'] is List) {
      for (final contributor in json['contributors'] as List) {
        if (contributor is Map && contributor['name'] != null) {
          contributorsList.add(contributor['name'] as String);
        }
      }
    }

    return TrackDetailModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      artistName: (json['artist'] is Map)
          ? (json['artist']['name'] as String? ?? '')
          : '',
      artistId: (json['artist'] is Map)
          ? (json['artist']['id'] as int? ?? 0)
          : 0,
      albumTitle: (json['album'] is Map)
          ? (json['album']['title'] as String? ?? '')
          : '',
      albumId: (json['album'] is Map) ? (json['album']['id'] as int? ?? 0) : 0,
      albumCoverSmall: (json['album'] is Map)
          ? (json['album']['cover_small'] as String? ?? '')
          : '',
      albumCoverMedium: (json['album'] is Map)
          ? (json['album']['cover_medium'] as String? ?? '')
          : '',
      albumCoverBig: (json['album'] is Map)
          ? (json['album']['cover_big'] as String? ?? '')
          : '',
      albumCoverXl: (json['album'] is Map)
          ? (json['album']['cover_xl'] as String? ?? '')
          : '',
      duration: json['duration'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      releaseDate: json['release_date'] as String? ?? '',
      explicitLyrics: json['explicit_lyrics'] as bool? ?? false,
      preview: json['preview'] as String? ?? '',
      bpm: (json['bpm'] is num) ? (json['bpm'] as num).toInt() : 0,
      gain: (json['gain'] is num) ? (json['gain'] as num).toDouble() : 0.0,
      diskNumber: json['disk_number'] as int? ?? 0,
      trackPosition: json['track_position'] as int? ?? 0,
      contributors: contributorsList,
    );
  }
}
