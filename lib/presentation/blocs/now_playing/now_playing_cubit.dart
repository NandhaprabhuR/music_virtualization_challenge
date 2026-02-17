import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:untitled1/domain/entities/track.dart';

/// State that holds the currently selected/playing track.
class NowPlayingState extends Equatable {
  final Track? currentTrack;

  const NowPlayingState({this.currentTrack});

  @override
  List<Object?> get props => [currentTrack];
}

/// Cubit that manages which track is currently "playing".
class NowPlayingCubit extends Cubit<NowPlayingState> {
  NowPlayingCubit() : super(const NowPlayingState());

  void selectTrack(Track track) {
    emit(NowPlayingState(currentTrack: track));
  }

  void clearTrack() {
    emit(const NowPlayingState());
  }

  bool get hasTrack => state.currentTrack != null;
}
