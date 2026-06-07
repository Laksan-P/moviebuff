import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/movie_catalog_utils.dart';
import '../utils/poster_decode.dart';

/// Canonical movie poster renderer — HTTP(S) network images only, never [Image.asset].
class MoviePoster extends StatefulWidget {
  const MoviePoster({
    super.key,
    required this.movie,
    this.title,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.decodeWidth = 200,
    this.borderRadius,
  });

  final Map<String, dynamic> movie;
  final String? title;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double decodeWidth;
  final BorderRadius? borderRadius;

  @override
  State<MoviePoster> createState() => _MoviePosterState();
}

class _MoviePosterState extends State<MoviePoster> {
  late final List<String> _urls;
  int _index = 0;
  bool _loggedSource = false;

  String get _title =>
      widget.title ?? widget.movie['title']?.toString() ?? 'Movie';

  @override
  void initState() {
    super.initState();
    _urls = MovieCatalogUtils.networkPosterCandidates(widget.movie);
  }

  @override
  void didUpdateWidget(covariant MoviePoster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movie != widget.movie) {
      _urls
        ..clear()
        ..addAll(MovieCatalogUtils.networkPosterCandidates(widget.movie));
      _index = 0;
      _loggedSource = false;
    }
  }

  void _logSourceOnce(String? url) {
    if (_loggedSource) return;
    _loggedSource = true;
    MovieCatalogUtils.logPosterSource(_title, url);
  }

  @override
  Widget build(BuildContext context) {
    final child = _buildChild(context);
    if (widget.borderRadius == null) return child;
    return ClipRRect(borderRadius: widget.borderRadius!, child: child);
  }

  Widget _buildChild(BuildContext context) {
    if (_index < _urls.length) {
      final url = _urls[_index];
      _logSourceOnce(url);
      final cacheW = posterDecodePixels(context, widget.decodeWidth);
      return Image.network(
        url,
        key: ValueKey<String>(url),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        cacheWidth: cacheW,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(context);
        },
        errorBuilder: (context, error, stackTrace) {
          MovieCatalogUtils.logPosterLoadFailed(_title, error, attemptedUrl: url);
          final next = _index + 1;
          if (next < _urls.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _index = next);
            });
          }
          return _placeholder(context);
        },
      );
    }

    _logSourceOnce(null);
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            size: widget.width != null && widget.width! < 80 ? 24 : 32,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          ),
          if (widget.height == null || widget.height! > 80) ...[
            const SizedBox(height: 6),
            Text(
              _title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
