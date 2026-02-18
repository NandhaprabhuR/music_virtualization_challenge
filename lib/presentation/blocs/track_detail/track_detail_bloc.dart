import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled1/core/errors/exceptions.dart';
import 'package:untitled1/domain/entities/lyrics.dart';
import 'package:untitled1/domain/usecases/get_lyrics.dart';
import 'package:untitled1/domain/usecases/get_track_details.dart';
import 'package:untitled1/presentation/blocs/track_detail/track_detail_event.dart';
import 'package:untitled1/presentation/blocs/track_detail/track_detail_state.dart';

class TrackDetailBloc extends Bloc<TrackDetailEvent, TrackDetailState> {
  final GetTrackDetails getTrackDetails;
  final GetLyrics getLyrics;

  /// In-memory lyrics cache keyed by "trackName|artistName"
  static final Map<String, Lyrics> _lyricsCache = {};

  TrackDetailBloc({required this.getTrackDetails, required this.getLyrics})
    : super(const TrackDetailInitialState()) {
    on<FetchTrackDetailEvent>(_onFetchTrackDetail);
    on<FetchLyricsEvent>(_onFetchLyrics);
  }

  static String _lyricsCacheKey(String trackName, String artistName) =>
      '${trackName.toLowerCase()}|${artistName.toLowerCase()}';

  Future<void> _onFetchTrackDetail(
    FetchTrackDetailEvent event,
    Emitter<TrackDetailState> emit,
  ) async {
    emit(const TrackDetailLoadingState());

    try {
      final detail = await getTrackDetails(trackId: event.trackId);

      emit(TrackDetailLoadedState(trackDetail: detail, isLyricsLoading: true));

      // Automatically fetch lyrics after loading details
      add(
        FetchLyricsEvent(
          trackName: detail.title,
          artistName: detail.artistName,
          albumName: detail.albumTitle,
          duration: detail.duration,
        ),
      );
    } on NoInternetException {
      emit(const TrackDetailNoInternetState());
    } on ServerException catch (e) {
      emit(TrackDetailErrorState(message: e.message));
    } catch (e) {
      emit(TrackDetailErrorState(message: e.toString()));
    }
  }

  Future<void> _onFetchLyrics(
    FetchLyricsEvent event,
    Emitter<TrackDetailState> emit,
  ) async {
    final currentState = state;

    if (currentState is TrackDetailLoadedState) {
      final cacheKey = _lyricsCacheKey(event.trackName, event.artistName);

      // Check cache first
      final cached = _lyricsCache[cacheKey];
      if (cached != null) {
        emit(currentState.copyWith(lyrics: cached, isLyricsLoading: false));
        return;
      }

      emit(currentState.copyWith(isLyricsLoading: true, lyricsError: null));

      try {
        final lyrics = await getLyrics(
          trackName: event.trackName,
          artistName: event.artistName,
          albumName: event.albumName,
          duration: event.duration,
        );

        // Cache the result
        if (lyrics.hasLyrics) {
          _lyricsCache[cacheKey] = lyrics;
        }

        emit(currentState.copyWith(lyrics: lyrics, isLyricsLoading: false));
      } on NoInternetException {
        emit(
          currentState.copyWith(
            isLyricsLoading: false,
            lyricsError: 'NO INTERNET CONNECTION',
          ),
        );
      } catch (e) {
        emit(
          currentState.copyWith(
            isLyricsLoading: false,
            lyricsError: 'Lyrics not available',
          ),
        );
      }
    }
  }
}
