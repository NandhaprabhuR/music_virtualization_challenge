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

  // Search-based paging state (primary: a-z queries as required by task)
  int _currentQueryIndex = 0;
  int _currentQueryOffset = 0;

  // Fallback: Playlist-based paging state (if search is geo-blocked)
  int _currentPlaylistIndex = 0;
  int _currentPageOffset = 0;
  bool _useSearchMode = true; // Start with search API (task requirement)

  // All loaded tracks for local search filtering
  final List<Track> _allTracks = [];

  // Set of track IDs to avoid duplicates
  final Set<int> _loadedTrackIds = {};

  // Persistent grouped map — incrementally updated, never rebuilt from scratch
  // during normal loading. This prevents the flat list from shifting.
  final Map<String, List<Track>> _groupedTracks = {};
  List<String> _groupKeys = [];

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

    _currentQueryIndex = 0;
    _currentQueryOffset = 0;
    _currentPlaylistIndex = 0;
    _currentPageOffset = 0;
    _loadedTrackIds.clear();
    _allTracks.clear();
    _groupedTracks.clear();
    _groupKeys.clear();
    _useSearchMode = true;

    try {
      final tracks = await _fetchNextBatch();

      if (tracks.isEmpty) {
        // Search mode returned nothing (geo-blocked), try playlist fallback
        _useSearchMode = false;
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
        _appendToGroups(fallbackTracks);
        emit(
          LibraryLoadedState(
            tracks: List.unmodifiable(_allTracks),
            groupedTracks: Map.unmodifiable(_groupedTracks),
            groupKeys: List.unmodifiable(_groupKeys),
            totalLoaded: _allTracks.length,
          ),
        );
        return;
      }

      _allTracks.addAll(tracks);
      _appendToGroups(tracks);
      emit(
        LibraryLoadedState(
          tracks: List.unmodifiable(_allTracks),
          groupedTracks: Map.unmodifiable(_groupedTracks),
          groupKeys: List.unmodifiable(_groupKeys),
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
        // Only mark as truly done if ALL queries are exhausted
        final allQueriesDone = _useSearchMode
            ? _currentQueryIndex >= ApiConstants.searchQueries.length
            : _currentPlaylistIndex >= ApiConstants.playlistIds.length;

        emit(
          currentState.copyWith(
            isLoadingMore: false,
            hasReachedMax: allQueriesDone,
          ),
        );
        return;
      }

      _allTracks.addAll(newTracks);
      _appendToGroups(newTracks);

      emit(
        currentState.copyWith(
          tracks: List.unmodifiable(_allTracks),
          groupedTracks: Map.unmodifiable(_groupedTracks),
          groupKeys: List.unmodifiable(_groupKeys),
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

    // Always filter locally from already-loaded tracks (instant, no API call)
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
        hasReachedMax: true,
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
      emit(
        LibraryLoadedState(
          tracks: List.unmodifiable(_allTracks),
          groupedTracks: Map.unmodifiable(_groupedTracks),
          groupKeys: List.unmodifiable(_groupKeys),
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
    if (_useSearchMode) {
      return _fetchFromSearch();
    } else {
      return _fetchFromPlaylists();
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

  /// Fetches tracks using Deezer search endpoint with paging.
  /// Each scroll loads the next page from the current query letter.
  /// When a query is exhausted, moves to the next letter (a→b→c→...→z→0→9).
  Future<List<Track>> _fetchFromSearch() async {
    final List<Track> batch = [];
    int apiCalls = 0;
    int consecutiveErrors = 0;

    while (_currentQueryIndex < ApiConstants.searchQueries.length) {
      final query = ApiConstants.searchQueries[_currentQueryIndex];

      // If this query has been paged too deep, move to next
      if (_currentQueryOffset >=
          ApiConstants.maxPagesPerQuery * ApiConstants.pageSize) {
        _currentQueryIndex++;
        _currentQueryOffset = 0;
        continue;
      }

      try {
        apiCalls++;

        final tracks = await getTracks(
          query: query,
          index: _currentQueryOffset,
          limit: ApiConstants.pageSize,
        );

        consecutiveErrors = 0; // reset on success
        _currentQueryOffset += ApiConstants.pageSize;

        if (tracks.isEmpty) {
          _currentQueryIndex++;
          _currentQueryOffset = 0;
          continue;
        }

        if (tracks.length < ApiConstants.pageSize) {
          _currentQueryIndex++;
          _currentQueryOffset = 0;
        }

        for (final track in tracks) {
          if (!_loadedTrackIds.contains(track.id)) {
            _loadedTrackIds.add(track.id);
            batch.add(track);
          }
        }

        // Got enough new tracks for this scroll? Return them.
        if (batch.length >= 20) break;

        // Safety: don't make too many calls in one scroll
        if (apiCalls >= 15) break;
      } on NoInternetException {
        rethrow;
      } catch (e) {
        consecutiveErrors++;
        // Don't permanently skip a query on CORS/network error.
        // Just advance the offset so we try a different page next time.
        _currentQueryOffset += ApiConstants.pageSize;
        // If too many consecutive errors, move to next query
        if (consecutiveErrors >= 3) {
          _currentQueryIndex++;
          _currentQueryOffset = 0;
          consecutiveErrors = 0;
        }
        // Safety: stop if too many errors
        if (apiCalls >= 15) break;
        continue;
      }
    }

    return batch;
  }

  /// Incrementally appends new tracks to the persistent grouped map.
  /// New tracks are added at the END of their respective group lists,
  /// and new groups are inserted in sorted order. This prevents
  /// existing items from shifting positions in the flat list.
  void _appendToGroups(List<Track> newTracks) {
    for (final track in newTracks) {
      final letter = track.groupLetter;
      if (!_groupedTracks.containsKey(letter)) {
        _groupedTracks[letter] = [];
        // Insert the new key in sorted position
        _groupKeys = _sortedKeys(_groupedTracks.keys);
      }
      _groupedTracks[letter]!.add(track);
    }
  }

  /// Groups tracks by first letter of title (A-Z, # for non-alpha).
  /// Used only for search results (one-shot, not incremental).
  Map<String, List<Track>> _groupTracks(List<Track> tracks) {
    final Map<String, List<Track>> grouped = {};

    for (final track in tracks) {
      final letter = track.groupLetter;
      grouped.putIfAbsent(letter, () => []);
      grouped[letter]!.add(track);
    }

    final sortedKeys = _sortedKeys(grouped.keys);
    return {for (final key in sortedKeys) key: grouped[key]!};
  }

  /// Returns keys sorted A-Z with # at the end.
  List<String> _sortedKeys(Iterable<String> keys) {
    final list = keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });
    return list;
  }
}
