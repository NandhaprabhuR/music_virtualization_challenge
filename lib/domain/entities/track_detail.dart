import 'package:equatable/equatable.dart';

class TrackDetail extends Equatable {
  final int id;
  final String title;
  final String artistName;
  final int artistId;
  final String albumTitle;
  final int albumId;
  final String albumCoverSmall;
  final String albumCoverMedium;
  final String albumCoverBig;
  final String albumCoverXl;
  final int duration;
  final int rank;
  final String releaseDate;
  final bool explicitLyrics;
  final String preview;
  final int bpm;
  final double gain;
  final int diskNumber;
  final int trackPosition;
  final List<String> contributors;

  const TrackDetail({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artistId,
    required this.albumTitle,
    required this.albumId,
    required this.albumCoverSmall,
    required this.albumCoverMedium,
    required this.albumCoverBig,
    required this.albumCoverXl,
    required this.duration,
    required this.rank,
    required this.releaseDate,
    required this.explicitLyrics,
    required this.preview,
    required this.bpm,
    required this.gain,
    required this.diskNumber,
    required this.trackPosition,
    required this.contributors,
  });

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [id];
}
