import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:untitled1/presentation/widgets/sticky_header_widget.dart';
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
    // Trigger when within 200px of the bottom
    return currentScroll >= (maxScroll - 200);
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
          style: GoogleFonts.playfairDisplay(
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
                        style: GoogleFonts.playfairDisplay(
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
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Build a flat list with interleaved headers for sticky behavior.
    // Each item is either a header or a track.
    final List<_ListItem> flatList = [];

    for (final key in state.groupKeys) {
      final tracksInGroup = state.groupedTracks[key]!;
      flatList.add(
        _ListItem(
          isHeader: true,
          headerLetter: key,
          headerCount: tracksInGroup.length,
        ),
      );
      for (final track in tracksInGroup) {
        flatList.add(_ListItem(isHeader: false, track: track));
      }
    }

    final totalItems = flatList.length + (state.isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      itemCount: totalItems,
      // Use addAutomaticKeepAlives: false and addRepaintBoundaries: false
      // for better memory performance with large lists
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        // Loading indicator at the bottom
        if (index >= flatList.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: context.accent),
            ),
          );
        }

        final item = flatList[index];

        if (item.isHeader) {
          return StickyHeaderWidget(
            letter: item.headerLetter!,
            count: item.headerCount!,
          );
        }

        return BlocBuilder<NowPlayingCubit, NowPlayingState>(
          builder: (context, nowPlayingState) {
            final isPlaying =
                nowPlayingState.currentTrack?.id == item.track!.id;
            return Container(
              color: isPlaying
                  ? context.accent.withValues(alpha: 0.1)
                  : Colors.transparent,
              child: TrackListItem(
                track: item.track!,
                onTap: () => _onTrackTap(item.track!),
                trailing: isPlaying
                    ? Icon(
                        Icons.equalizer_rounded,
                        color: context.accent,
                        size: 22,
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

/// Represents either a header or a track item in the flat list.
class _ListItem {
  final bool isHeader;
  final String? headerLetter;
  final int? headerCount;
  final Track? track;

  const _ListItem({
    required this.isHeader,
    this.headerLetter,
    this.headerCount,
    this.track,
  });
}
