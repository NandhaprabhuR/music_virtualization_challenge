import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:untitled1/core/theme/app_theme.dart';
import 'package:untitled1/domain/entities/track.dart';

class TrackListItem extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final Widget? trailing;

  const TrackListItem({
    super.key,
    required this.track,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: track.albumCoverSmall.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: track.albumCoverSmall,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: context.card,
                          child: Icon(
                            Icons.music_note,
                            color: context.textSecondary,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: context.card,
                          child: Icon(
                            Icons.music_note,
                            color: context.textSecondary,
                          ),
                        ),
                      )
                    : Container(
                        color: context.card,
                        child: Icon(
                          Icons.music_note,
                          color: context.textSecondary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artistName,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${track.id}',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondary.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (trailing != null)
              trailing!
            else
              Icon(Icons.chevron_right, color: context.textSecondary),
          ],
        ),
      ),
    );
  }
}
