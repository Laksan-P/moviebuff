import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../widgets/custom_button.dart';
import '../utils/movie_catalog_utils.dart';
import 'movie_details_screen.dart';
import '../services/movie_service.dart';
import '../services/showtime_service.dart';
import '../providers/movie_provider.dart';

class TheatreDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> theatre;

  const TheatreDetailsScreen({super.key, required this.theatre});

  @override
  State<TheatreDetailsScreen> createState() => _TheatreDetailsScreenState();
}

class _TheatreDetailsScreenState extends State<TheatreDetailsScreen> {
  List<Map<String, dynamic>> _movies = [];
  bool _isLoading = true;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this screen
    if (_hasLoadedOnce && mounted) {
      _loadMovies();
    }
    _hasLoadedOnce = true;
  }

  Future<void> _loadMovies() async {
    setState(() => _isLoading = true);

    final movieProv = context.read<MovieProvider>();
    final local = await MovieService.getMovies();
    final merged = MovieCatalogUtils.mergeCustomerMovieLists(
      movieProv.movies,
      local,
    );
    final allShowtimes = await ShowtimeService.getShowtimes();

    final targetTheatre = (widget.theatre['name'] as String).trim();

    debugPrint(
      '🎭 THEATRE DETAILS - Loading showtimes for: ${widget.theatre['name']}',
    );
    debugPrint('🎭 Total showtimes in system: ${allShowtimes.length}');

    bool movieBelongsToTheatre(Map<String, dynamic> movie) {
      final assigned = (movie['theatre'] as String? ?? '').trim();
      if (assigned.isNotEmpty) {
        return MovieCatalogUtils.theatresLooselyMatch(assigned, targetTheatre);
      }
      return MovieCatalogUtils.theatresLooselyMatch(
        MovieCatalogUtils.defaultExternalTheatre,
        targetTheatre,
      );
    }

    final filteredMovies = merged.where((movie) {
      final movieTitle = (movie['title'] as String).trim().toLowerCase();

      if (!movieBelongsToTheatre(movie)) return false;

      final movieShowtimes = allShowtimes.where((st) {
        final stMovie = (st['movie'] as String? ?? '').trim().toLowerCase();
        final stTheatre = (st['theatre'] as String? ?? '').trim();
        return stMovie == movieTitle &&
            MovieCatalogUtils.theatresLooselyMatch(stTheatre, targetTheatre);
      });

      if (movieShowtimes.isNotEmpty) {
        return movieShowtimes.any(
          (st) => !ShowtimeService.isShowtimePassed(st['time'], st['date']),
        );
      }

      final synthetic = ShowtimeService.buildExternalCatalogShowtimes(movie);
      return synthetic.any(
        (st) =>
            !ShowtimeService.isShowtimePassed(st['time'], st['date']) &&
            MovieCatalogUtils.theatresLooselyMatch(
              st['theatre']?.toString() ?? '',
              targetTheatre,
            ),
      );
    }).toList();

    debugPrint('🎭 Filtered movies for this theatre: ${filteredMovies.length}');

    if (mounted) {
      setState(() {
        _movies = filteredMovies;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.theatre['name'],
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theatre Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.theatre['name'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.7),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.theatre['location'],
                                style: GoogleFonts.outfit(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withValues(alpha: 0.9),
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Now Showing
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Now Showing',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_movies.length} Movies',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_movies.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.movie_filter_rounded,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No upcoming shows found',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back later for new movies and showtimes at this theatre.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _movies.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final movie = _movies[index];
                        return Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  bottomLeft: Radius.circular(14),
                                ),
                                child: _TheatreRowPoster(movie: movie),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        movie['title'] ?? 'Unknown Movie',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${movie['genre'] ?? 'Action'} • ${movie['duration'] == 0 ? 'N/A' : '${movie['duration']} mins'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      CustomButton(
                                        text: 'Book Now',
                                        height: 36,
                                        width: 140,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  MovieDetailsScreen(
                                                    movie: MovieCatalogUtils
                                                        .normalizeCustomerMovie(
                                                      Map<String, dynamic>.from(
                                                        movie,
                                                      ),
                                                    ),
                                                    theatreName:
                                                        widget.theatre['name'],
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

class _TheatreRowPoster extends StatefulWidget {
  const _TheatreRowPoster({required this.movie});

  final Map<String, dynamic> movie;

  @override
  State<_TheatreRowPoster> createState() => _TheatreRowPosterState();
}

class _TheatreRowPosterState extends State<_TheatreRowPoster> {
  late final List<String> _urls;
  int _index = 0;

  static String? _httpUrl(dynamic v) {
    final t = v?.toString().trim() ?? '';
    if (t.isEmpty || t == 'null') return null;
    if (t.startsWith('http')) return t;
    return null;
  }

  String get _title => widget.movie['title']?.toString() ?? 'Movie';

  @override
  void initState() {
    super.initState();
    final img = _httpUrl(widget.movie['image']);
    final poster = _httpUrl(widget.movie['posterUrl']);
    _urls = [];
    if (img != null) _urls.add(img);
    if (poster != null && poster != img) _urls.add(poster);
  }

  @override
  Widget build(BuildContext context) {
    const w = 110.0;
    const h = 160.0;

    if (_index < _urls.length) {
      final url = _urls[_index];
      return Image.network(
        url,
        key: ValueKey<String>(url),
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          MovieCatalogUtils.logPosterLoadFailed(_title, error);
          final next = _index + 1;
          if (next < _urls.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _index = next);
            });
          }
          return _placeholder(context, w, h);
        },
      );
    }

    final asset = widget.movie['image']?.toString() ?? '';
    if (asset.isNotEmpty && !asset.startsWith('http')) {
      return Image.asset(
        asset,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          MovieCatalogUtils.logPosterLoadFailed(_title, error);
          return _placeholder(context, w, h);
        },
      );
    }

    return _placeholder(context, w, h);
  }

  Widget _placeholder(BuildContext context, double w, double h) {
    return Container(
      width: w,
      height: h,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            size: 28,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 4),
          Text(
            _title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
