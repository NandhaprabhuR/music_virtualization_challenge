import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
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
                children: [
                  Text(
                    track.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artistName,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      color: context.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
