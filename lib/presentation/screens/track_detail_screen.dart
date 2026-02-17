import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:untitled1/domain/entities/track.dart';
import 'package:untitled1/domain/usecases/get_lyrics.dart';
import 'package:untitled1/domain/usecases/get_track_details.dart';
import 'package:untitled1/presentation/blocs/track_detail/track_detail_bloc.dart';
import 'package:untitled1/presentation/blocs/track_detail/track_detail_event.dart';
import 'package:untitled1/presentation/blocs/track_detail/track_detail_state.dart';
import 'package:untitled1/presentation/widgets/error_widget.dart';
import 'package:untitled1/presentation/widgets/loading_widget.dart';
import 'package:untitled1/presentation/widgets/no_internet_widget.dart';

class TrackDetailScreen extends StatelessWidget {
  final Track track;

  const TrackDetailScreen({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrackDetailBloc(
        getTrackDetails: GetIt.I<GetTrackDetails>(),
        getLyrics: GetIt.I<GetLyrics>(),
      )..add(FetchTrackDetailEvent(trackId: track.id)),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        body: BlocBuilder<TrackDetailBloc, TrackDetailState>(
          builder: (context, state) {
            if (state is TrackDetailLoadingState ||
                state is TrackDetailInitialState) {
              return const LoadingWidget(message: 'Loading track details...');
            }

            if (state is TrackDetailNoInternetState) {
              return SafeArea(
                child: Column(
                  children: [
                    _buildBackButton(context),
                    const Expanded(child: NoInternetWidget()),
                  ],
                ),
              );
            }

            if (state is TrackDetailErrorState) {
              return SafeArea(
                child: Column(
                  children: [
                    _buildBackButton(context),
                    Expanded(
                      child: AppErrorWidget(
                        message: state.message,
                        onRetry: () {
                          context.read<TrackDetailBloc>().add(
                            FetchTrackDetailEvent(trackId: track.id),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is TrackDetailLoadedState) {
              return _buildDetailContent(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildDetailContent(
    BuildContext context,
    TrackDetailLoadedState state,
  ) {
    final detail = state.trackDetail;

    return CustomScrollView(
      slivers: [
        // Collapsible app bar with album art
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: const Color(0xFF0F0F1A),
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (detail.albumCoverXl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: detail.albumCoverXl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.album,
                        size: 100,
                        color: Colors.white24,
                      ),
                    ),
                  )
                else
                  Container(
                    color: Colors.grey[900],
                    child: const Icon(
                      Icons.album,
                      size: 100,
                      color: Colors.white24,
                    ),
                  ),
                // Gradient overlay
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xFF0F0F1A)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Track info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  detail.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Artist
                Text(
                  detail.artistName,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // Album
                Text(
                  detail.albumTitle,
                  style: TextStyle(fontSize: 15, color: Colors.grey[400]),
                ),
                const SizedBox(height: 20),

                // Info chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.timer_outlined,
                      detail.formattedDuration,
                    ),
                    _buildInfoChip(Icons.trending_up, 'Rank: ${detail.rank}'),
                    if (detail.bpm > 0)
                      _buildInfoChip(Icons.speed, '${detail.bpm} BPM'),
                    if (detail.releaseDate.isNotEmpty)
                      _buildInfoChip(Icons.calendar_today, detail.releaseDate),
                    _buildInfoChip(
                      Icons.album,
                      'Disc ${detail.diskNumber}, Track ${detail.trackPosition}',
                    ),
                    if (detail.explicitLyrics)
                      _buildInfoChip(
                        Icons.explicit,
                        'Explicit',
                        color: Colors.redAccent,
                      ),
                    _buildInfoChip(Icons.tag, 'ID: ${detail.id}'),
                  ],
                ),

                // Contributors
                if (detail.contributors.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Contributors',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: detail.contributors.map((name) {
                      return Chip(
                        label: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: const Color(0xFF1A1A2E),
                        side: BorderSide(color: Colors.grey[700]!),
                      );
                    }).toList(),
                  ),
                ],

                // Divider before lyrics
                const SizedBox(height: 24),
                Divider(color: Colors.grey[800]),
                const SizedBox(height: 16),

                // Lyrics section
                Row(
                  children: [
                    const Icon(
                      Icons.lyrics_outlined,
                      color: Color(0xFF6C63FF),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Lyrics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (state.isLyricsLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildLyricsContent(state),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLyricsContent(TrackDetailLoadedState state) {
    if (state.isLyricsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      );
    }

    if (state.lyricsError != null) {
      if (state.lyricsError == 'NO INTERNET CONNECTION') {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, color: Colors.orangeAccent),
              SizedBox(width: 12),
              Text(
                'NO INTERNET CONNECTION',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            state.lyricsError!,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      );
    }

    if (state.lyrics != null && state.lyrics!.hasLyrics) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          state.lyrics!.plainLyrics.isNotEmpty
              ? state.lyrics!.plainLyrics
              : state.lyrics!.syncedLyrics,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            height: 1.8,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'No lyrics available for this track.',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color?.withValues(alpha: 0.5) ?? Colors.grey[700]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey[400]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color ?? Colors.grey[300]),
          ),
        ],
      ),
    );
  }
}
