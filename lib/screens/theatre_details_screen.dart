import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../widgets/custom_button.dart';
import 'movie_details_screen.dart';
import '../services/movie_service.dart';
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

    final movies = await MovieService.getMovies();
    final allShowtimes = await ShowtimeService.getShowtimes();

    debugPrint(
      '🎭 THEATRE DETAILS - Loading showtimes for: ${widget.theatre['name']}',
    );
    debugPrint('🎭 Total showtimes in system: ${allShowtimes.length}');

    // Filter movies that have showtimes at THIS theatre
    // AND at least one showtime is in the future
    final filteredMovies = movies.where((movie) {
      final movieTitle = (movie['title'] as String).trim().toLowerCase();
      final targetTheatre = (widget.theatre['name'] as String)
          .trim()
          .toLowerCase();

      // Check if movie is explicitly assigned to this theatre
      final assignedTheatre = (movie['theatre'] as String? ?? '')
          .trim()
          .toLowerCase();
      bool isAssignedToThisTheatre = assignedTheatre == targetTheatre;

      final movieShowtimes = allShowtimes.where((st) {
        final stMovie = (st['movie'] as String? ?? '').trim().toLowerCase();
        final stTheatre = (st['theatre'] as String? ?? '').trim().toLowerCase();
        return stMovie == movieTitle && stTheatre == targetTheatre;
      });

      // Show if it belongs to this theatre OR has showtimes here
      if (isAssignedToThisTheatre) return true;
      if (movieShowtimes.isEmpty) return false;

      // Check if at least one showtime is in the future
      bool hasUpcoming = movieShowtimes.any((st) {
        return !ShowtimeService.isShowtimePassed(st['time'], st['date']);
      });

      return hasUpcoming;
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
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
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
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.theatre['location'],
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.9),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Now Showing',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.headerBackground,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_movies.length} Movies',
                          style: GoogleFonts.outfit(
                            color: AppColors.primaryBlue,
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
                              color: AppColors.textMuted.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No upcoming shows found',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back later for new movies and showtimes at this theatre.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: AppColors.textMuted.withValues(
                                  alpha: 0.7,
                                ),
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
                            color: AppColors.cardGray,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  bottomLeft: Radius.circular(14),
                                ),
                                child:
                                    movie['image'] != null &&
                                        movie['image']!.startsWith('http')
                                    ? Image.network(
                                        movie['image']!,
                                        width: 110,
                                        height: 160,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                width: 110,
                                                height: 160,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      )
                                    : Image.asset(
                                        movie['image'] ?? '',
                                        width: 110,
                                        height: 160,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                width: 110,
                                                height: 160,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      ),
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
                                          color: AppColors.headerBackground,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${movie['genre'] ?? 'Action'} • ${movie['duration'] == 0 ? 'N/A' : '${movie['duration']} mins'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textMuted,
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
                                                    movie: movie,
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
