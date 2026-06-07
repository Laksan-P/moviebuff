import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/premium_screen_stack.dart';
import '../utils/movie_catalog_utils.dart';
import '../widgets/movie_poster.dart';
import 'movie_details_screen.dart';
import '../providers/movie_provider.dart';
import '../services/showtime_service.dart';

class TheatreDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> theatre;

  const TheatreDetailsScreen({super.key, required this.theatre});

  @override
  State<TheatreDetailsScreen> createState() => _TheatreDetailsScreenState();
}

class _TheatreDetailsScreenState extends State<TheatreDetailsScreen> {
  List<Map<String, dynamic>> _movies = [];
  bool _isLoading = true;
  int? _lastScheduledMoviesToken;
  MovieProvider? _movieProviderForListener;

  void _maybeScheduleLoad(MovieProvider prov) {
    if (!mounted || prov.awaitingCatalogueUi) return;
    final token = identityHashCode(prov.movies);
    if (_lastScheduledMoviesToken == token) return;
    _lastScheduledMoviesToken = token;
    _loadMovies();
  }

  void _onMovieProviderChanged() {
    if (!mounted) return;
    final prov = _movieProviderForListener;
    if (prov == null) return;
    if (prov.awaitingCatalogueUi) {
      _lastScheduledMoviesToken = null;
      return;
    }
    _maybeScheduleLoad(prov);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<MovieProvider>();
      _movieProviderForListener = p;
      p.addListener(_onMovieProviderChanged);
      _onMovieProviderChanged();
    });
  }

  @override
  void dispose() {
    _movieProviderForListener?.removeListener(_onMovieProviderChanged);
    super.dispose();
  }

  static dynamic _readField(Map<String, dynamic> row, String snake, String camel) {
    return row[snake] ?? row[camel];
  }

  static bool _sameId(dynamic a, dynamic b) {
    if (a == null || b == null) return false;
    return a.toString() == b.toString();
  }

  Future<void> _loadMovies() async {
    setState(() => _isLoading = true);

    final movieProv = context.read<MovieProvider>();
    final merged = movieProv.movies;
    final allShowtimes = movieProv.showtimes;

    debugPrint('CURRENT THEATRE: ${widget.theatre['id']}');
    debugPrint('TOTAL SHOWTIMES: ${movieProv.showtimes.length}');

    for (final s in movieProv.showtimes) {
      debugPrint(
        'SHOWTIME id=${s['id']} theatre_id=${s['theatre_id']} '
        'theatreId=${s['theatreId']} movie_id=${s['movie_id']} '
        'movieId=${s['movieId']}',
      );
    }

    final targetTheatreId = widget.theatre['id'];
    final targetTheatreName = (widget.theatre['name'] as String? ?? '').trim();

    debugPrint(
      '🎭 THEATRE DETAILS - Loading showtimes for: $targetTheatreName '
      '(id=$targetTheatreId)',
    );

    final theatreShowtimes = allShowtimes.where((st) {
      final stTheatreId = _readField(st, 'theatre_id', 'theatreId');
      final matchesTheatre = _sameId(stTheatreId, targetTheatreId) ||
          (stTheatreId == null &&
              MovieCatalogUtils.theatresLooselyMatch(
                (st['theatre'] as String? ?? '').trim(),
                targetTheatreName,
              ));
      if (!matchesTheatre) return false;
      return !ShowtimeService.isShowtimePassed(st['time'], st['date']);
    }).toList();

    debugPrint(
      '🎭 Upcoming showtimes for theatre $targetTheatreId: '
      '${theatreShowtimes.length}',
    );

    final movieIds = theatreShowtimes
        .map((st) => _readField(st, 'movie_id', 'movieId')?.toString())
        .whereType<String>()
        .toSet();

    final movieTitles = theatreShowtimes
        .map((st) => (st['movie'] as String? ?? '').trim().toLowerCase())
        .where((title) => title.isNotEmpty)
        .toSet();

    final filteredMovies = merged.where((movie) {
      final movieId = movie['id']?.toString();
      if (movieId != null && movieIds.contains(movieId)) return true;

      final title = (movie['title'] as String? ?? '').trim().toLowerCase();
      return movieTitles.contains(title);
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
    final prov = context.watch<MovieProvider>();

    if (prov.awaitingCatalogueUi) {
      final scheme = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: scheme.surface.withValues(alpha: 0.82),
          foregroundColor: scheme.onSurface,
          elevation: 0,
          title: Text(
            widget.theatre['name'].toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
        body: PremiumScreenStack(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading catalogue...',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: scheme.surface.withValues(alpha: 0.82),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        title: Text(
          widget.theatre['name'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: PremiumScreenStack(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 28 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Theatre Info Card
                  GlassCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.theater_comedy_rounded,
                              color: AppColors.cinemaGold,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.theatre['name'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: scheme.onSurface,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: scheme.onSurfaceVariant,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${widget.theatre['location']}',
                                style: GoogleFonts.outfit(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 15,
                                  height: 1.35,
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
                            color: scheme.surface.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: scheme.outlineVariant,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: scheme.brightness == Brightness.dark
                                      ? 0.35
                                      : 0.06,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, cardConstraints) {
                              final narrowCard = cardConstraints.maxWidth < 340;
                              return Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(14),
                                      bottomLeft: Radius.circular(14),
                                    ),
                                    child: MoviePoster(
                                      movie: movie,
                                      width: 110,
                                      height: 160,
                                      decodeWidth: 110,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: CustomButton(
                                              text: 'Book Now',
                                              height: 36,
                                              width: narrowCard
                                                  ? null
                                                  : 140,
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        MovieDetailsScreen(
                                                          movie: MovieCatalogUtils
                                                              .normalizeCustomerMovie(
                                                            Map<String,
                                                                    dynamic>.from(
                                                              movie,
                                                            ),
                                                          ),
                                                          theatreName:
                                                              widget.theatre[
                                                                  'name'],
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
      ),
    );
  }
}

