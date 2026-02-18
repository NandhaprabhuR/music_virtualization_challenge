import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled1/core/theme/app_theme.dart';
import 'package:untitled1/domain/entities/track.dart';
import 'package:untitled1/domain/usecases/get_lyrics.dart';
import 'package:untitled1/domain/usecases/get_track_details.dart';
import 'package:untitled1/presentation/blocs/audio/audio_player_cubit.dart';
import 'package:untitled1/presentation/blocs/now_playing/now_playing_cubit.dart';
import 'package:untitled1/presentation/blocs/track_detail/track_detail_bloc.dart';
import 'package:untitled1/presentation/blocs/track_detail/track_detail_event.dart';
import 'package:untitled1/presentation/blocs/track_detail/track_detail_state.dart';
import 'package:untitled1/presentation/widgets/no_internet_widget.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NowPlayingCubit, NowPlayingState>(
      builder: (context, nowPlayingState) {
        if (nowPlayingState.currentTrack == null) {
          return _buildEmptyState(context);
        }
        return BlocProvider(
          key: ValueKey(nowPlayingState.currentTrack!.id),
          create: (_) =>
              TrackDetailBloc(
                getTrackDetails: GetIt.I<GetTrackDetails>(),
                getLyrics: GetIt.I<GetLyrics>(),
              )..add(
                FetchTrackDetailEvent(
                  trackId: nowPlayingState.currentTrack!.id,
                ),
              ),
          child: _NowPlayingContent(track: nowPlayingState.currentTrack!),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: context.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.music_note_rounded,
                size: 56,
                color: context.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Track Selected',
              style: GoogleFonts.playfairDisplay(
                color: context.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a track from the Library to see\ndetails and lyrics here.',
              style: GoogleFonts.playfairDisplay(
                color: context.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NowPlayingContent extends StatefulWidget {
  final Track track;
  const _NowPlayingContent({required this.track});
  @override
  State<_NowPlayingContent> createState() => _NowPlayingContentState();
}

class _NowPlayingContentState extends State<_NowPlayingContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _lyricsScrollController = ScrollController();
  int _currentLyricIndex = -1;
  List<_SyncedLine>? _cachedSyncedLines;
  StreamSubscription<AudioPlayerState>? _audioSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.track.preview.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AudioPlayerCubit>().playUrl(widget.track.preview);
      });
    }
    // Listen to audio position changes for synced lyrics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioSub = context.read<AudioPlayerCubit>().stream.listen((audioState) {
        if (!mounted) return;
        if (_cachedSyncedLines != null && _cachedSyncedLines!.isNotEmpty) {
          final newIndex = _findCurrentLineIndex(_cachedSyncedLines!, audioState.position);
          if (newIndex != _currentLyricIndex) {
            setState(() {
              _currentLyricIndex = newIndex;
            });
            if (newIndex >= 0) {
              _scrollToLine(newIndex);
            }
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _audioSub?.cancel();
    _tabController.dispose();
    _lyricsScrollController.dispose();
    super.dispose();
  }

  List<_SyncedLine> _parseSyncedLyrics(String syncedLyrics) {
    final lines = syncedLyrics.split('\n');
    final result = <_SyncedLine>[];
    final regex = RegExp(r'\[(\d+):(\d+)\.(\d+)\]\s*(.*)');
    for (final line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millis = int.parse(
          match.group(3)!.padRight(3, '0').substring(0, 3),
        );
        final text = match.group(4)?.trim() ?? '';
        final time = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: millis,
        );
        result.add(_SyncedLine(time: time, text: text));
      }
    }
    return result;
  }

  int _findCurrentLineIndex(List<_SyncedLine> lines, Duration position) {
    int idx = -1;
    for (int i = 0; i < lines.length; i++) {
      if (position >= lines[i].time) {
        idx = i;
      } else {
        break;
      }
    }
    return idx;
  }

  void _scrollToLine(int index) {
    if (!_lyricsScrollController.hasClients) return;
    final targetOffset = (index * 56.0) - 120.0;
    _lyricsScrollController.animateTo(
      targetOffset.clamp(0.0, _lyricsScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: BlocBuilder<TrackDetailBloc, TrackDetailState>(
        builder: (context, state) {
          if (state is TrackDetailLoadingState ||
              state is TrackDetailInitialState) {
            return _buildLoadingState(context);
          }
          if (state is TrackDetailNoInternetState) {
            return const SafeArea(child: NoInternetWidget());
          }
          if (state is TrackDetailErrorState) {
            return _buildErrorState(context, state.message);
          }
          if (state is TrackDetailLoadedState) {
            return _buildPlayerUI(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: context.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: CircularProgressIndicator(color: context.accent),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            widget.track.title,
            style: GoogleFonts.playfairDisplay(
              color: context.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.track.artistName,
            style: GoogleFonts.playfairDisplay(
              color: context.textSecondary,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Text(
              'Loading details...',
              style: GoogleFonts.playfairDisplay(
                color: context.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: context.accent),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.playfairDisplay(
                color: context.textSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => context.read<TrackDetailBloc>().add(
                FetchTrackDetailEvent(trackId: widget.track.id),
              ),
              icon: Icon(Icons.refresh, color: context.accent),
              label: Text(
                'Retry',
                style: GoogleFonts.playfairDisplay(color: context.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerUI(BuildContext context, TrackDetailLoadedState state) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: context.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: context.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: context.textSecondary,
              labelStyle: GoogleFonts.playfairDisplay(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.playfairDisplay(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Details'),
                Tab(text: 'Lyrics'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(context, state),
                _buildLyricsTab(context, state),
              ],
            ),
          ),
          _buildPlaybackControls(context, bottomPadding),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(BuildContext context, double bottomPadding) {
    return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
      builder: (context, audioState) {
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: bottomPadding + 12,
          ),
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF0A0A0A) : Colors.white,
            border: Border(top: BorderSide(color: context.dividerColor)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 5,
                  ),
                  activeTrackColor: context.accent,
                  inactiveTrackColor: context.textSecondary.withValues(
                    alpha: 0.2,
                  ),
                  thumbColor: context.accent,
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                ),
                child: Slider(
                  value: audioState.position.inMilliseconds.toDouble().clamp(
                    0,
                    audioState.duration.inMilliseconds.toDouble().clamp(
                      1,
                      double.infinity,
                    ),
                  ),
                  max: audioState.duration.inMilliseconds.toDouble().clamp(
                    1,
                    double.infinity,
                  ),
                  onChanged: (v) => context.read<AudioPlayerCubit>().seekTo(
                    Duration(milliseconds: v.toInt()),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(audioState.position),
                      style: GoogleFonts.playfairDisplay(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatDuration(audioState.duration),
                      style: GoogleFonts.playfairDisplay(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () =>
                        context.read<AudioPlayerCubit>().seekTo(Duration.zero),
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      color: context.textSecondary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => context
                        .read<AudioPlayerCubit>()
                        .togglePlayPause(widget.track.preview),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: context.accent,
                        shape: BoxShape.circle,
                      ),
                      child: audioState.status == PlaybackStatus.loading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Icon(
                              audioState.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      if (audioState.duration > Duration.zero) {
                        context.read<AudioPlayerCubit>().seekTo(
                          audioState.duration - const Duration(seconds: 1),
                        );
                      }
                    },
                    icon: Icon(
                      Icons.skip_next_rounded,
                      color: context.textSecondary,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailsTab(BuildContext context, TrackDetailLoadedState state) {
    final detail = state.trackDetail;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: context.accent.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: detail.albumCoverXl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: detail.albumCoverXl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: context.card,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: context.accent,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: context.card,
                          child: Icon(
                            Icons.album,
                            size: 80,
                            color: context.textSecondary,
                          ),
                        ),
                      )
                    : Container(
                        color: context.card,
                        child: Icon(
                          Icons.album,
                          size: 80,
                          color: context.textSecondary,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            detail.title,
            style: GoogleFonts.playfairDisplay(
              color: context.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            detail.artistName,
            style: GoogleFonts.playfairDisplay(
              color: context.accent,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail.albumTitle,
            style: GoogleFonts.playfairDisplay(
              color: context.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(16),
              border: context.isDark
                  ? null
                  : Border.all(color: context.dividerColor),
            ),
            child: Column(
              children: [
                _buildInfoRow(context, 'Track ID', '${detail.id}'),
                _buildDivider(context),
                _buildInfoRow(context, 'Duration', detail.formattedDuration),
                _buildDivider(context),
                _buildInfoRow(context, 'Rank', '${detail.rank}'),
                if (detail.bpm > 0) ...[
                  _buildDivider(context),
                  _buildInfoRow(context, 'BPM', '${detail.bpm}'),
                ],
                if (detail.releaseDate.isNotEmpty) ...[
                  _buildDivider(context),
                  _buildInfoRow(context, 'Release', detail.releaseDate),
                ],
                _buildDivider(context),
                _buildInfoRow(
                  context,
                  'Position',
                  'Disc ${detail.diskNumber}, Track ${detail.trackPosition}',
                ),
                if (detail.explicitLyrics) ...[
                  _buildDivider(context),
                  _buildInfoRow(
                    context,
                    'Content',
                    'Explicit',
                    valueColor: context.accent,
                  ),
                ],
              ],
            ),
          ),
          if (detail.contributors.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.card,
                borderRadius: BorderRadius.circular(16),
                border: context.isDark
                    ? null
                    : Border.all(color: context.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contributors',
                    style: GoogleFonts.playfairDisplay(
                      color: context.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: detail.contributors.map((name) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          name,
                          style: GoogleFonts.playfairDisplay(
                            color: context.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLyricsTab(BuildContext context, TrackDetailLoadedState state) {
    if (state.isLyricsLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: context.accent, strokeWidth: 2),
            const SizedBox(height: 16),
            Text(
              'Loading lyrics...',
              style: GoogleFonts.playfairDisplay(
                color: context.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (state.lyricsError != null) {
      if (state.lyricsError == 'NO INTERNET CONNECTION') {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, color: context.accent, size: 48),
              const SizedBox(height: 16),
              Text(
                'NO INTERNET CONNECTION',
                style: GoogleFonts.playfairDisplay(
                  color: context.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lyrics_outlined, color: context.textSecondary, size: 48),
            const SizedBox(height: 16),
            Text(
              state.lyricsError!,
              style: GoogleFonts.playfairDisplay(
                color: context.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    if (state.lyrics != null && state.lyrics!.hasLyrics) {
      if (state.lyrics!.syncedLyrics.isNotEmpty) {
        return _buildSyncedLyricsView(context, state.lyrics!.syncedLyrics);
      }
      final lines = state.lyrics!.plainLyrics.split('\n');
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        itemCount: lines.length,
        itemBuilder: (context, index) {
          final line = lines[index].trim();
          if (line.isEmpty) return const SizedBox(height: 20);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              line,
              style: GoogleFonts.playfairDisplay(
                color: index == 0
                    ? context.textPrimary
                    : context.textPrimary.withValues(alpha: 0.6),
                fontSize: index == 0 ? 26 : 22,
                fontWeight: index == 0 ? FontWeight.bold : FontWeight.w500,
                height: 1.4,
              ),
            ),
          );
        },
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lyrics_outlined, color: context.textSecondary, size: 56),
          const SizedBox(height: 16),
          Text(
            'No lyrics available',
            style: GoogleFonts.playfairDisplay(
              color: context.textPrimary.withValues(alpha: 0.5),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lyrics for this track could not be found.',
            style: GoogleFonts.playfairDisplay(
              color: context.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncedLyricsView(BuildContext context, String syncedLyrics) {
    _cachedSyncedLines ??= _parseSyncedLyrics(syncedLyrics);
    final syncedLines = _cachedSyncedLines!;
    if (syncedLines.isEmpty) {
      return Center(
        child: Text(
          'No synced lyrics available',
          style: GoogleFonts.playfairDisplay(
            color: context.textSecondary,
            fontSize: 15,
          ),
        ),
      );
    }

    final currentIndex = _currentLyricIndex;

    return ListView.builder(
      controller: _lyricsScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      itemCount: syncedLines.length,
      itemBuilder: (context, index) {
        final line = syncedLines[index];
        final isActive = index == currentIndex;
        final isPast = index < currentIndex;
        if (line.text.isEmpty) return const SizedBox(height: 24);
        return GestureDetector(
          onTap: () => context.read<AudioPlayerCubit>().seekTo(line.time),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.playfairDisplay(
                color: isActive
                    ? context.accent
                    : isPast
                        ? context.textPrimary.withValues(alpha: 0.35)
                        : context.textPrimary.withValues(alpha: 0.6),
                fontSize: isActive ? 26 : 20,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                height: 1.4,
              ),
              child: Text(line.text),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.playfairDisplay(
              color: context.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              color: valueColor ?? context.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(color: context.dividerColor, height: 1);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _SyncedLine {
  final Duration time;
  final String text;
  const _SyncedLine({required this.time, required this.text});
}
