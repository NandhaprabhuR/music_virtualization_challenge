import 'package:hive/hive.dart';
import 'package:untitled1/domain/entities/track.dart';

// Hive adapter is hand-written in hive/adapters/track_adapter.dart
@HiveType(typeId: 0)
class TrackModel extends Track {
  @HiveField(0)
  final int trackId;

  @HiveField(1)
  final String trackTitle;

  @HiveField(2)
  final String trackArtistName;

  @HiveField(3)
  final int trackDuration;

  @HiveField(4)
  final String trackAlbumTitle;

  @HiveField(5)
  final String trackAlbumCoverSmall;

  @HiveField(6)
  final String trackAlbumCoverMedium;

  @HiveField(7)
  final String trackPreview;

  const TrackModel({
    required this.trackId,
    required this.trackTitle,
    required this.trackArtistName,
    required this.trackDuration,
    required this.trackAlbumTitle,
    required this.trackAlbumCoverSmall,
    required this.trackAlbumCoverMedium,
    required this.trackPreview,
  }) : super(
         id: trackId,
         title: trackTitle,
         artistName: trackArtistName,
         duration: trackDuration,
         albumTitle: trackAlbumTitle,
         albumCoverSmall: trackAlbumCoverSmall,
         albumCoverMedium: trackAlbumCoverMedium,
         preview: trackPreview,
       );

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      trackId: json['id'] as int? ?? 0,
      trackTitle: json['title'] as String? ?? '',
      trackArtistName: (json['artist'] is Map)
          ? (json['artist']['name'] as String? ?? '')
          : '',
      trackDuration: json['duration'] as int? ?? 0,
      trackAlbumTitle: (json['album'] is Map)
          ? (json['album']['title'] as String? ?? '')
          : '',
      trackAlbumCoverSmall: (json['album'] is Map)
          ? (json['album']['cover_small'] as String? ?? '')
          : '',
      trackAlbumCoverMedium: (json['album'] is Map)
          ? (json['album']['cover_medium'] as String? ?? '')
          : '',
      trackPreview: json['preview'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': trackId,
      'title': trackTitle,
      'artist': {'name': trackArtistName},
      'duration': trackDuration,
      'album': {
        'title': trackAlbumTitle,
        'cover_small': trackAlbumCoverSmall,
        'cover_medium': trackAlbumCoverMedium,
      },
      'preview': trackPreview,
    };
  }

  factory TrackModel.fromEntity(Track track) {
    return TrackModel(
      trackId: track.id,
      trackTitle: track.title,
      trackArtistName: track.artistName,
      trackDuration: track.duration,
      trackAlbumTitle: track.albumTitle,
      trackAlbumCoverSmall: track.albumCoverSmall,
      trackAlbumCoverMedium: track.albumCoverMedium,
      trackPreview: track.preview,
    );
  }
}
