import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';

enum PlaybackStatus { idle, loading, playing, paused, error }

class AudioPlayerState extends Equatable {
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;
  final String? error;

  const AudioPlayerState({
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  AudioPlayerState copyWith({
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    String? error,
  }) {
    return AudioPlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error,
    );
  }

  bool get isPlaying => status == PlaybackStatus.playing;

  @override
  List<Object?> get props => [status, position, duration, error];
}

class AudioPlayerCubit extends Cubit<AudioPlayerState> {
  final AudioPlayer _player = AudioPlayer();
  String? _currentUrl;
  bool _isLoadingUrl = false;

  AudioPlayerCubit() : super(const AudioPlayerState()) {
    _player.positionStream.listen((pos) {
      if (!isClosed) {
        emit(
          AudioPlayerState(
            status: state.status,
            position: pos,
            duration: state.duration,
            error: state.error,
          ),
        );
      }
    });

    _player.durationStream.listen((dur) {
      if (!isClosed && dur != null) {
        emit(
          AudioPlayerState(
            status: state.status,
            position: state.position,
            duration: dur,
            error: state.error,
          ),
        );
      }
    });

    _player.playerStateStream.listen((playerState) {
      if (isClosed) return;

      // Handle track completion
      if (playerState.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
        emit(
          state.copyWith(
            status: PlaybackStatus.paused,
            position: Duration.zero,
          ),
        );
        return;
      }

      // Only use stream to transition loading → playing
      // (pause/resume are handled immediately by pause()/playUrl())
      if (playerState.processingState == ProcessingState.ready &&
          playerState.playing &&
          state.status == PlaybackStatus.loading) {
        emit(state.copyWith(status: PlaybackStatus.playing));
      }
    });
  }

  Future<void> playUrl(String url) async {
    if (url.isEmpty || _isLoadingUrl) return;

    try {
      // Resume same track
      if (_currentUrl == url && state.status == PlaybackStatus.paused) {
        _player.play();
        emit(state.copyWith(status: PlaybackStatus.playing));
        return;
      }

      // New track - stop current, load new
      _isLoadingUrl = true;
      emit(state.copyWith(status: PlaybackStatus.loading));
      _currentUrl = url;

      await _player.stop();
      await _player.setUrl(url);
      _player.play();
      emit(state.copyWith(status: PlaybackStatus.playing));
    } catch (e) {
      // Retry once
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        await _player.setUrl(url);
        _player.play();
        emit(state.copyWith(status: PlaybackStatus.playing));
      } catch (_) {
        emit(
          state.copyWith(
            status: PlaybackStatus.error,
            error: 'Preview unavailable – try another track',
          ),
        );
      }
    } finally {
      _isLoadingUrl = false;
    }
  }

  void pause() {
    _player.pause();
    emit(state.copyWith(status: PlaybackStatus.paused));
  }

  void togglePlayPause(String url) {
    if (_isLoadingUrl) return;
    if (state.status == PlaybackStatus.playing) {
      pause();
    } else if (state.status == PlaybackStatus.paused && _currentUrl == url) {
      _player.play();
      emit(state.copyWith(status: PlaybackStatus.playing));
    } else {
      playUrl(url);
    }
  }

  void seekTo(Duration position) {
    _player.seek(position);
  }

  void stop() {
    _player.stop();
    _currentUrl = null;
    emit(const AudioPlayerState());
  }

  @override
  Future<void> close() {
    _player.dispose();
    return super.close();
  }
}
