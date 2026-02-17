import 'package:equatable/equatable.dart';

abstract class TrackDetailEvent extends Equatable {
  const TrackDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch full track details from Deezer API.
class FetchTrackDetailEvent extends TrackDetailEvent {
  final int trackId;

  const FetchTrackDetailEvent({required this.trackId});

  @override
  List<Object?> get props => [trackId];
}

/// Fetch lyrics from LRCLIB.
class FetchLyricsEvent extends TrackDetailEvent {
  final String trackName;
  final String artistName;
  final String albumName;
  final int duration;

  const FetchLyricsEvent({
    required this.trackName,
    required this.artistName,
    required this.albumName,
    required this.duration,
  });

  @override
  List<Object?> get props => [trackName, artistName, albumName, duration];
}
