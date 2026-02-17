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

  AudioPlayerCubit() : super(const AudioPlayerState()) {
    _player.positionStream.listen((pos) {
      if (!isClosed) {
        emit(state.copyWith(position: pos));
      }
    });

    _player.durationStream.listen((dur) {
      if (!isClosed && dur != null) {
        emit(state.copyWith(duration: dur));
      }
    });

    _player.playerStateStream.listen((playerState) {
      if (isClosed) return;

      if (playerState.processingState == ProcessingState.completed) {
        emit(
          state.copyWith(
            status: PlaybackStatus.paused,
            position: Duration.zero,
          ),
        );
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  Future<void> playUrl(String url) async {
    if (url.isEmpty) return;

    try {
      if (_currentUrl == url && state.status == PlaybackStatus.paused) {
        await _player.play();
        emit(state.copyWith(status: PlaybackStatus.playing));
        return;
      }

      emit(state.copyWith(status: PlaybackStatus.loading));
      _currentUrl = url;

      await _player.setUrl(url);
      await _player.play();
      emit(state.copyWith(status: PlaybackStatus.playing));
    } catch (e) {
      emit(
        state.copyWith(
          status: PlaybackStatus.error,
          error: 'Could not play audio',
        ),
      );
    }
  }

  void pause() {
    _player.pause();
    emit(state.copyWith(status: PlaybackStatus.paused));
  }

  void togglePlayPause(String url) {
    if (state.isPlaying) {
      pause();
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
