import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled1/core/theme/app_theme.dart';
import 'package:untitled1/core/utils/debouncer.dart';
import 'package:untitled1/domain/entities/track.dart';
import 'package:untitled1/presentation/blocs/connectivity/connectivity_cubit.dart';
import 'package:untitled1/presentation/blocs/library/library_bloc.dart';
import 'package:untitled1/presentation/blocs/theme/theme_cubit.dart';
import 'package:untitled1/presentation/blocs/library/library_event.dart';
import 'package:untitled1/presentation/blocs/library/library_state.dart';
import 'package:untitled1/presentation/blocs/now_playing/now_playing_cubit.dart';
import 'package:untitled1/presentation/widgets/error_widget.dart';
import 'package:untitled1/presentation/widgets/loading_widget.dart';
import 'package:untitled1/presentation/widgets/no_internet_widget.dart';
import 'package:untitled1/presentation/widgets/search_bar_widget.dart';
import 'package:untitled1/presentation/widgets/track_list_item.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 500),
  );
  bool _initialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      context.read<LibraryBloc>().add(const LoadTracksEvent());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final state = context.read<LibraryBloc>().state;
      if (state is LibraryLoadedState) {
        if (state.isSearchMode) {
          context.read<LibraryBloc>().add(const LoadMoreSearchResultsEvent());
        } else {
          context.read<LibraryBloc>().add(const LoadMoreTracksEvent());
        }
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Trigger when within 500px of the bottom (pre-fetch early)
    return currentScroll >= (maxScroll - 500);
  }

  void _onSearchChanged(String query) {
    _debouncer.run(() {
      if (query.trim().isEmpty) {
        context.read<LibraryBloc>().add(const ClearSearchEvent());
      } else {
        context.read<LibraryBloc>().add(SearchTracksEvent(query: query));
      }
    });
  }

  void _onClearSearch() {
    _debouncer.cancel();
    context.read<LibraryBloc>().add(const ClearSearchEvent());
  }

  void _onTrackTap(Track track) {
    context.read<NowPlayingCubit>().selectTrack(track);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(
          'Library',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
            fontSize: 28,
          ),
        ),
        backgroundColor: context.bg,
        elevation: 0,
        actions: [
          BlocBuilder<LibraryBloc, LibraryState>(
            builder: (context, state) {
              if (state is LibraryLoadedState) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.totalLoaded} tracks',
                        style: TextStyle(
                          color: context.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Theme toggle
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return IconButton(
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.wb_sunny_rounded
                      : Icons.nightlight_round,
                  color: context.accent,
                  size: 22,
                ),
                tooltip: themeMode == ThemeMode.dark
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
              );
            },
          ),
          // Connectivity indicator
          BlocBuilder<ConnectivityCubit, bool>(
            builder: (context, isConnected) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? Colors.green : Colors.redAccent,
                  size: 18,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          SearchBarWidget(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onClear: _onClearSearch,
          ),
          // Track list
          Expanded(
            child: BlocBuilder<LibraryBloc, LibraryState>(
              builder: (context, state) {
                if (state is LibraryInitialState ||
                    state is LibraryLoadingState) {
                  return const LoadingWidget(message: 'Loading tracks...');
                }

                if (state is LibraryNoInternetState) {
                  return NoInternetWidget(
                    onRetry: () {
                      context.read<LibraryBloc>().add(const LoadTracksEvent());
                    },
                  );
                }

                if (state is LibraryErrorState) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: () {
                      context.read<LibraryBloc>().add(const LoadTracksEvent());
                    },
                  );
                }

                if (state is LibraryLoadedState) {
                  return _buildTrackList(state);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a flat list of items (headers + tracks) from the grouped data.
  /// Returns a record of (flatItems, headerIndices) where each flat item is
  /// either a _HeaderItem or a _TrackItem.
  ({List<_ListItem> items, List<int> headerIndices}) _buildFlatList(
    LibraryLoadedState state,
  ) {
    final List<_ListItem> items = [];
    final List<int> headerIndices = [];

    for (final key in state.groupKeys) {
      final tracksInGroup = state.groupedTracks[key]!;
      headerIndices.add(items.length);
      items.add(_HeaderItem(letter: key, count: tracksInGroup.length));
      for (final track in tracksInGroup) {
        items.add(_TrackItem(track: track));
      }
    }
    return (items: items, headerIndices: headerIndices);
  }

  Widget _buildTrackList(LibraryLoadedState state) {
    if (state.tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, size: 64, color: context.textSecondary),
            const SizedBox(height: 16),
            Text(
              state.isSearchMode
                  ? 'No tracks found for "${state.searchQuery}"'
                  : 'No tracks available',
              style: TextStyle(fontSize: 16, color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    final flatData = _buildFlatList(state);
    final flatItems = flatData.items;
    final headerIndices = flatData.headerIndices;

    // Total items = flat list + optional loading indicator
    final totalCount = flatItems.length + (state.isLoadingMore ? 1 : 0);

    return _StickyHeaderListView(
      scrollController: _scrollController,
      flatItems: flatItems,
      headerIndices: headerIndices,
      totalCount: totalCount,
      isLoadingMore: state.isLoadingMore,
      onTrackTap: _onTrackTap,
    );
  }
}

// ─── Flat list item types ────────────────────────────────────────────────────

sealed class _ListItem {}

class _HeaderItem extends _ListItem {
  final String letter;
  final int count;
  _HeaderItem({required this.letter, required this.count});
}

class _TrackItem extends _ListItem {
  final Track track;
  _TrackItem({required this.track});
}

// ─── Sticky-header ListView ─────────────────────────────────────────────────

/// Renders a flat list (headers + tracks) with a single sticky header overlay.
/// Uses pre-computed scroll offsets from fixed item heights — no GlobalKey
/// measurement needed, so it works reliably on web and mobile.
class _StickyHeaderListView extends StatefulWidget {
  final ScrollController scrollController;
  final List<_ListItem> flatItems;
  final List<int> headerIndices;
  final int totalCount;
  final bool isLoadingMore;
  final ValueChanged<Track> onTrackTap;

  const _StickyHeaderListView({
    required this.scrollController,
    required this.flatItems,
    required this.headerIndices,
    required this.totalCount,
    required this.isLoadingMore,
    required this.onTrackTap,
  });

  @override
  State<_StickyHeaderListView> createState() => _StickyHeaderListViewState();
}

class _StickyHeaderListViewState extends State<_StickyHeaderListView> {
  static const double _headerHeight = 48.0;
  static const double _trackHeight = 96.0;

  /// Index into headerIndices for the currently stuck header.
  int _stuckSection = 0;

  /// Vertical offset for the push-up animation (0 = fully visible, negative = pushed up).
  double _stuckOffset = 0.0;

  /// Pre-computed scroll offset (in px) at which each header appears in the list.
  List<double> _headerScrollOffsets = [];

  @override
  void initState() {
    super.initState();
    _computeHeaderOffsets();
    widget.scrollController.addListener(_updateSticky);
  }

  @override
  void didUpdateWidget(covariant _StickyHeaderListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flatItems.length != oldWidget.flatItems.length ||
        widget.headerIndices.length != oldWidget.headerIndices.length) {
      _stuckSection = 0;
      _stuckOffset = 0.0;
      _computeHeaderOffsets();
      // Re-run sticky calculation with new offsets
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateSticky();
      });
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_updateSticky);
    super.dispose();
  }

  /// Computes the absolute scroll offset for each header in the flat list.
  /// Since we know every item's height, this is just a cumulative sum.
  void _computeHeaderOffsets() {
    _headerScrollOffsets = [];
    double offset = 0.0;
    for (int i = 0; i < widget.flatItems.length; i++) {
      if (widget.flatItems[i] is _HeaderItem) {
        _headerScrollOffsets.add(offset);
      }
      offset += widget.flatItems[i] is _HeaderItem
          ? _headerHeight
          : _trackHeight;
    }
  }

  void _updateSticky() {
    if (!mounted || !widget.scrollController.hasClients) return;
    if (_headerScrollOffsets.isEmpty) return;

    final scrollOffset = widget.scrollController.offset;

    int newStuck = 0;
    double newOffset = 0.0;

    // Binary-search style: find the last header whose offset <= scrollOffset
    for (int i = 0; i < _headerScrollOffsets.length; i++) {
      if (_headerScrollOffsets[i] <= scrollOffset) {
        newStuck = i;
      } else {
        // This header is below the current scroll position.
        // Check if it's close enough to push the stuck header up.
        final distanceFromTop = _headerScrollOffsets[i] - scrollOffset;
        if (distanceFromTop < _headerHeight) {
          newOffset = distanceFromTop - _headerHeight; // negative = pushed up
        }
        break;
      }
    }

    if (newStuck != _stuckSection || newOffset != _stuckOffset) {
      setState(() {
        _stuckSection = newStuck;
        _stuckOffset = newOffset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stuckHeader =
        _headerScrollOffsets.isNotEmpty &&
            _stuckSection < widget.headerIndices.length
        ? widget.flatItems[widget.headerIndices[_stuckSection]] as _HeaderItem
        : null;

    return Stack(
      children: [
        // The actual scrollable list — no top padding needed; the first item IS the header
        ListView.builder(
          controller: widget.scrollController,
          itemCount: widget.totalCount,
          itemBuilder: (ctx, index) {
            if (index >= widget.flatItems.length) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: context.accent),
                ),
              );
            }

            final item = widget.flatItems[index];

            if (item is _HeaderItem) {
              return SizedBox(
                height: _headerHeight,
                child: _buildHeaderContent(item),
              );
            } else if (item is _TrackItem) {
              return SizedBox(
                height: _trackHeight,
                child: _buildTrackRow(item),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // Floating sticky header overlay
        if (stuckHeader != null)
          Positioned(
            top: _stuckOffset,
            left: 0,
            right: 0,
            height: _headerHeight,
            child: _buildHeaderContent(stuckHeader),
          ),
      ],
    );
  }

  Widget _buildHeaderContent(_HeaderItem item) {
    return Container(
      height: _headerHeight,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: context.card,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                item.letter,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${item.count} tracks',
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackRow(_TrackItem item) {
    return BlocBuilder<NowPlayingCubit, NowPlayingState>(
      builder: (context, nowPlayingState) {
        final isPlaying = nowPlayingState.currentTrack?.id == item.track.id;
        return Container(
          color: isPlaying
              ? context.accent.withValues(alpha: 0.1)
              : Colors.transparent,
          child: TrackListItem(
            track: item.track,
            onTap: () => widget.onTrackTap(item.track),
            trailing: isPlaying
                ? Icon(Icons.equalizer_rounded, color: context.accent, size: 22)
                : null,
          ),
        );
      },
    );
  }
}
