import 'package:equatable/equatable.dart';
import 'package:untitled1/domain/entities/lyrics.dart';
import 'package:untitled1/domain/entities/track_detail.dart';

abstract class TrackDetailState extends Equatable {
  const TrackDetailState();

  @override
  List<Object?> get props => [];
}

class TrackDetailInitialState extends TrackDetailState {
  const TrackDetailInitialState();
}

class TrackDetailLoadingState extends TrackDetailState {
  const TrackDetailLoadingState();
}

class TrackDetailLoadedState extends TrackDetailState {
  final TrackDetail trackDetail;
  final Lyrics? lyrics;
  final bool isLyricsLoading;
  final String? lyricsError;

  const TrackDetailLoadedState({
    required this.trackDetail,
    this.lyrics,
    this.isLyricsLoading = false,
    this.lyricsError,
  });

  TrackDetailLoadedState copyWith({
    TrackDetail? trackDetail,
    Lyrics? lyrics,
    bool? isLyricsLoading,
    String? lyricsError,
  }) {
    return TrackDetailLoadedState(
      trackDetail: trackDetail ?? this.trackDetail,
      lyrics: lyrics ?? this.lyrics,
      isLyricsLoading: isLyricsLoading ?? this.isLyricsLoading,
      lyricsError: lyricsError ?? this.lyricsError,
    );
  }

  @override
  List<Object?> get props => [
    trackDetail,
    lyrics,
    isLyricsLoading,
    lyricsError,
  ];
}

class TrackDetailErrorState extends TrackDetailState {
  final String message;

  const TrackDetailErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

class TrackDetailNoInternetState extends TrackDetailState {
  const TrackDetailNoInternetState();
}
