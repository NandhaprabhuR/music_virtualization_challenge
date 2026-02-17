import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled1/core/constants/api_constants.dart';
import 'package:untitled1/core/errors/exceptions.dart';
import 'package:untitled1/domain/entities/track.dart';
import 'package:untitled1/domain/usecases/get_tracks.dart';
import 'package:untitled1/domain/usecases/search_tracks.dart';
import 'package:untitled1/presentation/blocs/library/library_event.dart';
import 'package:untitled1/presentation/blocs/library/library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final GetTracks getTracks;
  final SearchTracks searchTracks;

  // Playlist-based paging state
  int _currentPlaylistIndex = 0;
  int _currentPageOffset = 0;

  // Fallback: search-based paging state (if search endpoint works)
  int _currentQueryIndex = 0;
  int _currentQueryOffset = 0;
  bool _usePlaylistMode = true; // Start with playlists

  // All loaded tracks for local search filtering
  final List<Track> _allTracks = [];

  // Set of track IDs to avoid duplicates
  final Set<int> _loadedTrackIds = {};

  LibraryBloc({required this.getTracks, required this.searchTracks})
    : super(const LibraryInitialState()) {
    on<LoadTracksEvent>(_onLoadTracks);
    on<LoadMoreTracksEvent>(_onLoadMoreTracks);
    on<SearchTracksEvent>(_onSearchTracks);
    on<LoadMoreSearchResultsEvent>(_onLoadMoreSearchResults);
    on<ClearSearchEvent>(_onClearSearch);
  }

  Future<void> _onLoadTracks(
    LoadTracksEvent event,
    Emitter<LibraryState> emit,
  ) async {
    emit(const LibraryLoadingState());

    _currentPlaylistIndex = 0;
    _currentPageOffset = 0;
    _currentQueryIndex = 0;
    _currentQueryOffset = 0;
    _loadedTrackIds.clear();
    _allTracks.clear();
    _usePlaylistMode = true;

    try {
      final tracks = await _fetchNextBatch();

      if (tracks.isEmpty) {
        // Playlist mode returned nothing, try search mode as fallback
        _usePlaylistMode = false;
        final fallbackTracks = await _fetchNextBatch();
        if (fallbackTracks.isEmpty) {
          emit(
            const LibraryLoadedState(
              tracks: [],
              groupedTracks: {},
              groupKeys: [],
              hasReachedMax: true,
            ),
          );
          return;
        }
        _allTracks.addAll(fallbackTracks);
        final grouped = _groupTracks(_allTracks);
        emit(
          LibraryLoadedState(
            tracks: List.unmodifiable(_allTracks),
            groupedTracks: grouped,
            groupKeys: grouped.keys.toList(),
            totalLoaded: _allTracks.length,
          ),
        );
        return;
      }

      _allTracks.addAll(tracks);
      final grouped = _groupTracks(_allTracks);
      emit(
        LibraryLoadedState(
          tracks: List.unmodifiable(_allTracks),
          groupedTracks: grouped,
          groupKeys: grouped.keys.toList(),
          totalLoaded: _allTracks.length,
        ),
      );
    } on NoInternetException {
      emit(const LibraryNoInternetState());
    } catch (e) {
      emit(LibraryErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadMoreTracks(
    LoadMoreTracksEvent event,
    Emitter<LibraryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LibraryLoadedState ||
        currentState.hasReachedMax ||
        currentState.isLoadingMore ||
        currentState.isSearchMode) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final newTracks = await _fetchNextBatch();

      if (newTracks.isEmpty) {
        emit(currentState.copyWith(isLoadingMore: false, hasReachedMax: true));
        return;
      }

      _allTracks.addAll(newTracks);
      final grouped = _groupTracks(_allTracks);

      emit(
        currentState.copyWith(
          tracks: List.unmodifiable(_allTracks),
          groupedTracks: grouped,
          groupKeys: grouped.keys.toList(),
          isLoadingMore: false,
          totalLoaded: _allTracks.length,
        ),
      );
    } on NoInternetException {
      emit(currentState.copyWith(isLoadingMore: false));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onSearchTracks(
    SearchTracksEvent event,
    Emitter<LibraryState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      add(const ClearSearchEvent());
      return;
    }

    // First try Deezer search API (works outside India)
    emit(const LibraryLoadingState());

    try {
      final results = await searchTracks(
        query: query,
        index: 0,
        limit: ApiConstants.pageSize,
      );

      if (results.isNotEmpty) {
        // Search API works — use remote results
        final grouped = _groupTracks(results);
        emit(
          LibraryLoadedState(
            tracks: results,
            groupedTracks: grouped,
            groupKeys: grouped.keys.toList(),
            isSearchMode: true,
            searchQuery: query,
            hasReachedMax: results.length < ApiConstants.pageSize,
            totalLoaded: results.length,
          ),
        );
        return;
      }
    } catch (_) {
      // Search API failed/geo-blocked — fall through to local filter
    }

    // Fallback: filter locally from already-loaded tracks
    final lowerQuery = query.toLowerCase();
    final filtered = _allTracks.where((t) {
      return t.title.toLowerCase().contains(lowerQuery) ||
          t.artistName.toLowerCase().contains(lowerQuery) ||
          t.albumTitle.toLowerCase().contains(lowerQuery);
    }).toList();

    final grouped = _groupTracks(filtered);
    emit(
      LibraryLoadedState(
        tracks: filtered,
        groupedTracks: grouped,
        groupKeys: grouped.keys.toList(),
        isSearchMode: true,
        searchQuery: query,
        hasReachedMax: true, // local filter — no more pages
        totalLoaded: filtered.length,
      ),
    );
  }

  Future<void> _onLoadMoreSearchResults(
    LoadMoreSearchResultsEvent event,
    Emitter<LibraryState> emit,
  ) async {
    // For local search, all results are already returned.
    // For remote search, we could paginate but it's unlikely to work
    // if the initial search succeeded, we don't need more for now.
    final currentState = state;
    if (currentState is! LibraryLoadedState ||
        currentState.hasReachedMax ||
        currentState.isLoadingMore ||
        !currentState.isSearchMode) {
      return;
    }
    // Mark as reached max since local search returns all results
    emit(currentState.copyWith(hasReachedMax: true));
  }

  Future<void> _onClearSearch(
    ClearSearchEvent event,
    Emitter<LibraryState> emit,
  ) async {
    // Restore full library view from already-loaded tracks
    if (_allTracks.isNotEmpty) {
      final grouped = _groupTracks(_allTracks);
      emit(
        LibraryLoadedState(
          tracks: List.unmodifiable(_allTracks),
          groupedTracks: grouped,
          groupKeys: grouped.keys.toList(),
          totalLoaded: _allTracks.length,
        ),
      );
    } else {
      add(const LoadTracksEvent());
    }
  }

  /// Fetches the next batch of tracks.
  /// In playlist mode: cycles through Deezer playlists.
  /// In search mode (fallback): cycles through a-z, 0-9 queries.
  Future<List<Track>> _fetchNextBatch() async {
    if (_usePlaylistMode) {
      return _fetchFromPlaylists();
    } else {
      return _fetchFromSearch();
    }
  }

  /// Fetches tracks from Deezer playlists endpoint (works globally).
  Future<List<Track>> _fetchFromPlaylists() async {
    final List<Track> batch = [];
    final playlists = ApiConstants.playlistIds;

    while (batch.length < ApiConstants.playlistPageSize &&
        _currentPlaylistIndex < playlists.length) {
      final playlistId = playlists[_currentPlaylistIndex];

      try {
        final tracks = await getTracks.fromPlaylist(
          playlistId: playlistId,
          index: _currentPageOffset,
          limit: ApiConstants.playlistPageSize,
        );

        if (tracks.isEmpty) {
          // This playlist is exhausted, move to next
          _currentPlaylistIndex++;
          _currentPageOffset = 0;
          continue;
        }

        // Deduplicate
        for (final track in tracks) {
          if (!_loadedTrackIds.contains(track.id)) {
            _loadedTrackIds.add(track.id);
            batch.add(track);
          }
        }

        _currentPageOffset += tracks.length;

        // If fewer returned than requested, playlist exhausted
        if (tracks.length < ApiConstants.playlistPageSize) {
          _currentPlaylistIndex++;
          _currentPageOffset = 0;
        }
      } on NoInternetException {
        rethrow;
      } catch (e) {
        // Skip failed playlist, try next
        _currentPlaylistIndex++;
        _currentPageOffset = 0;
        continue;
      }
    }

    return batch;
  }

  /// Fallback: fetches tracks using search endpoint (may be geo-blocked).
  Future<List<Track>> _fetchFromSearch() async {
    final List<Track> batch = [];

    while (batch.length < ApiConstants.pageSize &&
        _currentQueryIndex < ApiConstants.searchQueries.length) {
      final query = ApiConstants.searchQueries[_currentQueryIndex];

      try {
        final tracks = await getTracks(
          query: query,
          index: _currentQueryOffset,
          limit: ApiConstants.pageSize,
        );

        if (tracks.isEmpty ||
            _currentQueryOffset >=
                ApiConstants.maxPagesPerQuery * ApiConstants.pageSize) {
          _currentQueryIndex++;
          _currentQueryOffset = 0;
          continue;
        }

        for (final track in tracks) {
          if (!_loadedTrackIds.contains(track.id)) {
            _loadedTrackIds.add(track.id);
            batch.add(track);
          }
        }

        _currentQueryOffset += ApiConstants.pageSize;

        if (tracks.length < ApiConstants.pageSize) {
          _currentQueryIndex++;
          _currentQueryOffset = 0;
        }
      } on NoInternetException {
        rethrow;
      } catch (e) {
        _currentQueryIndex++;
        _currentQueryOffset = 0;
        continue;
      }
    }

    return batch;
  }

  /// Groups tracks by first letter of title (A-Z, # for non-alpha).
  /// Returns a sorted map.
  Map<String, List<Track>> _groupTracks(List<Track> tracks) {
    final Map<String, List<Track>> grouped = {};

    for (final track in tracks) {
      final letter = track.groupLetter;
      grouped.putIfAbsent(letter, () => []);
      grouped[letter]!.add(track);
    }

    // Sort keys: A-Z first, then #
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });

    return {for (final key in sortedKeys) key: grouped[key]!};
  }
}
