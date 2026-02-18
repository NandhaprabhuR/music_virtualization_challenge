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
  bool _useSearchMode = true; // Search is primary (task requirement)
  bool _searchGeoBlocked = false; // True if Deezer search returns empty data

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
    _useSearchMode = true; // search is primary (task requirement)
    _isFirstLoad = true;
    _searchGeoBlocked = false;
    _consecutiveEmptySearches = 0;

    try {
      final tracks = await _fetchNextBatch();

      if (tracks.isEmpty) {
        // Try playlists as fallback if search is geo-blocked
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
        // If search exhausted or geo-blocked, switch to playlists
        if (_useSearchMode) {
          final searchDone =
              _currentQueryIndex >= ApiConstants.searchQueries.length ||
              _searchGeoBlocked;
          if (searchDone) {
            _useSearchMode = false;
            // Don't mark as reached max — let playlist mode try
            emit(currentState.copyWith(isLoadingMore: false));
            return;
          }
        }

        // Only mark as truly done if ALL sources are exhausted
        final allDone = _useSearchMode
            ? (_currentQueryIndex >= ApiConstants.searchQueries.length ||
                      _searchGeoBlocked) &&
                  _currentPlaylistIndex >= ApiConstants.playlistIds.length
            : _currentPlaylistIndex >= ApiConstants.playlistIds.length;

        emit(
          currentState.copyWith(isLoadingMore: false, hasReachedMax: allDone),
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
  /// In search mode (primary): cycles through a-z, 0-9 queries via Deezer Search API.
  /// In playlist mode (fallback): cycles through Deezer playlists if search is geo-blocked.
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

  bool _isFirstLoad = true;

  /// Fetches tracks using Deezer search endpoint with paging.
  /// First load: single fast API call so UI renders instantly.
  /// Subsequent loads: fires 3 parallel API calls for throughput.
  /// Detects geo-blocking (empty results) and sets _searchGeoBlocked.
  int _consecutiveEmptySearches = 0;

  Future<List<Track>> _fetchFromSearch() async {
    if (_searchGeoBlocked) return [];

    final List<Track> batch = [];

    // ── FIRST LOAD: one fast call, return immediately ─────────────────
    if (_isFirstLoad) {
      _isFirstLoad = false;
      if (_currentQueryIndex < ApiConstants.searchQueries.length) {
        try {
          final tracks = await getTracks(
            query: ApiConstants.searchQueries[_currentQueryIndex],
            index: _currentQueryOffset,
            limit: ApiConstants.pageSize,
          );
          _currentQueryOffset += ApiConstants.pageSize;
          if (tracks.isEmpty || tracks.length < ApiConstants.pageSize) {
            _currentQueryIndex++;
            _currentQueryOffset = 0;
          }
          for (final track in tracks) {
            if (!_loadedTrackIds.contains(track.id)) {
              _loadedTrackIds.add(track.id);
              batch.add(track);
            }
          }
          // Detect geo-blocking: if search returned 0 usable tracks
          if (batch.isEmpty) {
            _consecutiveEmptySearches++;
            if (_consecutiveEmptySearches >= 2) {
              _searchGeoBlocked = true;
            }
          } else {
            _consecutiveEmptySearches = 0;
          }
        } on NoInternetException {
          rethrow;
        } catch (_) {
          _currentQueryIndex++;
          _currentQueryOffset = 0;
        }
      }
      return batch;
    }

    // ── SUBSEQUENT LOADS: parallel calls for speed ────────────────────
    int apiCalls = 0;
    const maxApiCalls = 9; // 3 rounds × 3 parallel = 9 total max

    while (_currentQueryIndex < ApiConstants.searchQueries.length &&
        apiCalls < maxApiCalls) {
      // Skip exhausted queries
      if (_currentQueryOffset >=
          ApiConstants.maxPagesPerQuery * ApiConstants.pageSize) {
        _currentQueryIndex++;
        _currentQueryOffset = 0;
        continue;
      }

      final query = ApiConstants.searchQueries[_currentQueryIndex];
      final offset = _currentQueryOffset;

      // Fire up to 3 calls for consecutive pages of the same query
      final List<Future<List<Track>>> futures = [];
      final List<int> offsets = [];
      for (int p = 0; p < 3 && apiCalls + p < maxApiCalls; p++) {
        final o = offset + p * ApiConstants.pageSize;
        if (o >= ApiConstants.maxPagesPerQuery * ApiConstants.pageSize) break;
        offsets.add(o);
        futures.add(
          getTracks(
            query: query,
            index: o,
            limit: ApiConstants.pageSize,
          ).catchError((_) => <Track>[]),
        );
      }
      apiCalls += futures.length;

      if (futures.isEmpty) {
        _currentQueryIndex++;
        _currentQueryOffset = 0;
        continue;
      }

      final results = await Future.wait(futures);

      bool queryExhausted = false;
      for (int i = 0; i < results.length; i++) {
        final tracks = results[i];
        if (tracks.isEmpty || tracks.length < ApiConstants.pageSize) {
          queryExhausted = true;
        }
        for (final track in tracks) {
          if (!_loadedTrackIds.contains(track.id)) {
            _loadedTrackIds.add(track.id);
            batch.add(track);
          }
        }
      }

      if (queryExhausted) {
        _currentQueryIndex++;
        _currentQueryOffset = 0;
      } else {
        _currentQueryOffset = offsets.last + ApiConstants.pageSize;
      }

      // Got enough tracks? Return early.
      if (batch.length >= 20) break;
    }

    // Detect geo-blocking after parallel fetches
    if (batch.isEmpty && apiCalls > 0) {
      _consecutiveEmptySearches++;
      if (_consecutiveEmptySearches >= 2) {
        _searchGeoBlocked = true;
      }
    } else if (batch.isNotEmpty) {
      _consecutiveEmptySearches = 0;
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
