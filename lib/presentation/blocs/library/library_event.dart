import 'package:equatable/equatable.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load — starts fetching tracks from the first query character.
class LoadTracksEvent extends LibraryEvent {
  const LoadTracksEvent();
}

/// Load next page of tracks (infinite scroll trigger).
class LoadMoreTracksEvent extends LibraryEvent {
  const LoadMoreTracksEvent();
}

/// User typed a search query.
class SearchTracksEvent extends LibraryEvent {
  final String query;

  const SearchTracksEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Load more search results (infinite scroll in search mode).
class LoadMoreSearchResultsEvent extends LibraryEvent {
  const LoadMoreSearchResultsEvent();
}

/// Clear search and return to full library.
class ClearSearchEvent extends LibraryEvent {
  const ClearSearchEvent();
}
