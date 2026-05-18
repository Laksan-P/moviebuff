import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/poster_decode.dart';

class MovieCard extends StatelessWidget {
  final String title;
  final String genre;
  final String rating;
  final String imageUrl;
  final VoidCallback onTap;
  final double cardWidth;

  const MovieCard({
    super.key,
    required this.title,
    required this.genre,
    required this.rating,
    required this.imageUrl,
    required this.onTap,
    this.cardWidth = 160,
  });

  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cacheW = posterDecodePixels(context, cardWidth);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    cacheWidth: cacheW,
                    gaplessPlayback: true,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.movie_creation_outlined,
                            size: 48,
                            color: scheme.outline,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 130,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.88),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFE8C547),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              genre,
                              style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
