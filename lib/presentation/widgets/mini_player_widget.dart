import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled1/core/theme/app_theme.dart';
import 'package:untitled1/presentation/blocs/audio/audio_player_cubit.dart';
import 'package:untitled1/presentation/blocs/now_playing/now_playing_cubit.dart';

class MiniPlayerWidget extends StatelessWidget {
  final VoidCallback onTap;

  const MiniPlayerWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NowPlayingCubit, NowPlayingState>(
      builder: (context, nowPlaying) {
        if (nowPlaying.currentTrack == null) {
          return const SizedBox.shrink();
        }
        final track = nowPlaying.currentTrack!;
        return BlocBuilder<AudioPlayerCubit, AudioPlayerState>(
          buildWhen: (prev, curr) =>
              prev.status != curr.status ||
              prev.position.inSeconds != curr.position.inSeconds,
          builder: (context, audioState) {
            final progress = audioState.duration.inMilliseconds > 0
                ? (audioState.position.inMilliseconds /
                          audioState.duration.inMilliseconds)
                      .clamp(0.0, 1.0)
                : 0.0;

            return GestureDetector(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFF5F5F5),
                  border: Border(
                    top: BorderSide(color: context.dividerColor, width: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress bar at top
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(context.accent),
                      minHeight: 2,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // Album art
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: track.albumCoverSmall.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: track.albumCoverSmall,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: context.card,
                                        child: Icon(
                                          Icons.music_note,
                                          color: context.textSecondary,
                                          size: 20,
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: context.card,
                                        child: Icon(
                                          Icons.music_note,
                                          color: context.textSecondary,
                                          size: 20,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: context.card,
                                      child: Icon(
                                        Icons.music_note,
                                        color: context.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Track info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  track.title,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  track.artistName,
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Play/Pause button
                          GestureDetector(
                            onTap: () => context
                                .read<AudioPlayerCubit>()
                                .togglePlayPause(track.preview),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: context.accent,
                                shape: BoxShape.circle,
                              ),
                              child: audioState.status == PlaybackStatus.loading
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      audioState.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
