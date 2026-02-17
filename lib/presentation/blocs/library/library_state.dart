import 'package:equatable/equatable.dart';
import 'package:untitled1/domain/entities/track.dart';

abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

class LibraryInitialState extends LibraryState {
  const LibraryInitialState();
}

class LibraryLoadingState extends LibraryState {
  const LibraryLoadingState();
}

class LibraryLoadedState extends LibraryState {
  final List<Track> tracks;
  final Map<String, List<Track>> groupedTracks;
  final List<String> groupKeys;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool isSearchMode;
  final String searchQuery;
  final int totalLoaded;

  const LibraryLoadedState({
    required this.tracks,
    required this.groupedTracks,
    required this.groupKeys,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.isSearchMode = false,
    this.searchQuery = '',
    this.totalLoaded = 0,
  });

  LibraryLoadedState copyWith({
    List<Track>? tracks,
    Map<String, List<Track>>? groupedTracks,
    List<String>? groupKeys,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? isSearchMode,
    String? searchQuery,
    int? totalLoaded,
  }) {
    return LibraryLoadedState(
      tracks: tracks ?? this.tracks,
      groupedTracks: groupedTracks ?? this.groupedTracks,
      groupKeys: groupKeys ?? this.groupKeys,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSearchMode: isSearchMode ?? this.isSearchMode,
      searchQuery: searchQuery ?? this.searchQuery,
      totalLoaded: totalLoaded ?? this.totalLoaded,
    );
  }

  @override
  List<Object?> get props => [
    tracks.length,
    hasReachedMax,
    isLoadingMore,
    isSearchMode,
    searchQuery,
    totalLoaded,
  ];
}

class LibraryErrorState extends LibraryState {
  final String message;

  const LibraryErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

class LibraryNoInternetState extends LibraryState {
  final List<Track> cachedTracks;

  const LibraryNoInternetState({this.cachedTracks = const []});

  @override
  List<Object?> get props => [cachedTracks.length];
}
