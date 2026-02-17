import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled1/domain/entities/track.dart';
import 'package:untitled1/presentation/blocs/now_playing/now_playing_cubit.dart';

class MiniPlayerWidget extends StatelessWidget {
  final VoidCallback onTap;

  const MiniPlayerWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NowPlayingCubit, NowPlayingState>(
      builder: (context, state) {
        if (state.currentTrack == null) {
          return const SizedBox.shrink();
        }

        final track = state.currentTrack!;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Album art
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: _buildAlbumArt(track),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Track info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artistName,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Play indicator
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.grey[500],
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumArt(Track track) {
    if (track.albumCoverSmall.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: track.albumCoverSmall,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: const Color(0xFF2A2A3E),
          child: const Icon(Icons.music_note, color: Colors.white30, size: 20),
        ),
        errorWidget: (context, url, error) => Container(
          color: const Color(0xFF2A2A3E),
          child: const Icon(Icons.music_note, color: Colors.white30, size: 20),
        ),
      );
    }
    return Container(
      color: const Color(0xFF2A2A3E),
      child: const Icon(Icons.music_note, color: Colors.white30, size: 20),
    );
  }
}
