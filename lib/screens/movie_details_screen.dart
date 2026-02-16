import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'booking_screen.dart';
import '../services/showtime_service.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> movie;
  final String? theatreName;

  const MovieDetailsScreen({super.key, required this.movie, this.theatreName});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  // Filter selections
  late String selectedDate;
  String selectedLanguage = 'Language';
  String selectedFormat = 'Format';
  String selectedPrice = 'Price Range';
  String selectedTime = 'Show Timings';

  List<Map<String, dynamic>> allShowtimes = [];
  bool _isloadingShowtimes = true;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _initializeSelectedDate();
    _loadShowtimes();
    debugPrint('🎬 MOVIE DETAILS - Received Movie Data: ${widget.movie}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this screen
    if (_hasLoadedOnce && mounted) {
      _loadShowtimes();
    }
    _hasLoadedOnce = true;
  }

  void _initializeSelectedDate() {
    selectedDate = 'Today';
  }

  Future<void> _loadShowtimes() async {
    setState(() => _isloadingShowtimes = true);

    final showtimes = await ShowtimeService.getShowtimes();

    debugPrint(
      '🎬 MOVIE DETAILS - Total showtimes loaded: ${showtimes.length}',
    );
    debugPrint('🎬 Looking for showtimes for movie: ${widget.movie['title']}');

    if (mounted) {
      setState(() {
        allShowtimes = showtimes;
        _isloadingShowtimes = false;
      });
    }
  }

  List<String> _generateDates() {
    final List<String> dates = ['All Dates', 'Today', 'Tomorrow'];
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    // Generate next 5 days (total 7 days including Today and Tomorrow)
    for (int i = 2; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final dayStr = date.day.toString().padLeft(2, '0');
      final monthStr = months[date.month - 1].toUpperCase();
      final yearStr = date.year.toString();

      final label = '$monthStr $dayStr, $yearStr';
      if (!dates.contains(label)) dates.add(label);
    }
    return dates;
  }

  List<Map<String, dynamic>> _getFilteredShowtimes() {
    return allShowtimes.where((st) {
      // 1. Movie Filter
      final stMovie = (st['movie'] as String? ?? '').trim().toLowerCase();
      final targetMovie = (widget.movie['title'] as String)
          .trim()
          .toLowerCase();
      if (stMovie != targetMovie) return false;

      // 2. Theatre Filter
      if (widget.theatreName != null) {
        final stTheatre = (st['theatre'] as String? ?? '').trim().toLowerCase();
        final targetTheatre = widget.theatreName!.trim().toLowerCase();
        if (stTheatre != targetTheatre) return false;
      }

      // 3. Date Filter
      if (selectedDate != 'All Dates') {
        String targetIsoDate = _getIsoDateFromLabel(selectedDate);
        if (st['date'] != targetIsoDate) return false;
      }

      // 4. Past Showtime Filter
      if (ShowtimeService.isShowtimePassed(st['time'], st['date'])) {
        return false;
      }

      // 5. Language Filter
      if (selectedLanguage != 'Language' &&
          st['language'] != selectedLanguage) {
        return false;
      }

      // 6. Format Filter
      if (selectedFormat != 'Format' && st['format'] != selectedFormat) {
        return false;
      }

      // 7. Time Filter
      if (selectedTime != 'Show Timings') {
        final timeStr = st['time'] as String;
        final isPM = timeStr.contains('PM');
        final parts = timeStr.split(' ')[0].split(':');
        final hour = int.parse(parts[0]);
        final actualHour = (isPM && hour != 12)
            ? hour + 12
            : (!isPM && hour == 12 ? 0 : hour);

        if (selectedTime.contains('Morning') &&
            (actualHour < 9 || actualHour >= 12)) {
          return false;
        }
        if (selectedTime.contains('Afternoon') &&
            (actualHour < 12 || actualHour >= 16)) {
          return false;
        }
        if (selectedTime.contains('Evening') &&
            (actualHour < 16 || actualHour >= 19)) {
          return false;
        }
        if (selectedTime.contains('Night') && actualHour < 19) return false;
      }

      return true;
    }).toList();
  }

  String _getIsoDateFromLabel(String label) {
    if (label == 'All Dates') return ''; // No filtering

    final now = DateTime.now();

    if (label == 'Today') {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }

    if (label == 'Tomorrow') {
      final tomorrow = now.add(const Duration(days: 1));
      return '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    }

    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    try {
      final parts = label.replaceAll(',', '').split(' ');
      if (parts.length != 3) return label;

      final monthIndex = months.indexOf(parts[0].toUpperCase());
      if (monthIndex == -1) return label;

      final month = monthIndex + 1;
      final day = parts[1];
      final year = parts[2];
      return '$year-${month.toString().padLeft(2, '0')}-${day.padLeft(2, '0')}';
    } catch (e) {
      return label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cast = [
      {'name': 'Actor 1', 'role': 'Role 1'},
      {'name': 'Actor 2', 'role': 'Role 2'},
      {'name': 'Actor 3', 'role': 'Role 3'},
    ];

    final filteredShowtimes = _getFilteredShowtimes();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isloadingShowtimes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trailer / Poster Section
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 260,
                            height: 380,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              image: DecorationImage(
                                image:
                                    widget.movie['image'] != null &&
                                        widget.movie['image']!.startsWith(
                                          'http',
                                        )
                                    ? NetworkImage(widget.movie['image']!)
                                    : AssetImage(widget.movie['image'] ?? '')
                                          as ImageProvider,
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  debugPrint('❌ IMAGE ERROR: $exception');
                                },
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                final String? trailerUrl =
                                    widget.movie['trailerUrl'];

                                // Diagnostic Feedback
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        trailerUrl == null
                                            ? 'DEBUG: trailerUrl is NULL'
                                            : (trailerUrl.isEmpty
                                                  ? 'DEBUG: trailerUrl is EMPTY'
                                                  : 'DEBUG: Launching $trailerUrl'),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }

                                if (trailerUrl != null &&
                                    trailerUrl.isNotEmpty) {
                                  String urlToLaunch = trailerUrl;
                                  if (!urlToLaunch.startsWith('http')) {
                                    urlToLaunch = 'https://$urlToLaunch';
                                  }

                                  final uri = Uri.parse(urlToLaunch);
                                  try {
                                    // Skipping canLaunchUrl as it often throws MissingPluginException
                                    // during development after adding a new plugin. Direct launch is safer.
                                    final success = await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                    if (!success) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.platformDefault,
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(40),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.4),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Text(
                            widget.movie['title'] ?? 'Unknown',
                            textAlign: TextAlign.center,
                            softWrap: true,
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              widget.movie['rating'] ?? 'N/A',
                              style: GoogleFonts.outfit(
                                color: Colors.amber[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            _dot(context),
                            Text(
                              '${widget.movie['duration'] ?? 0} mins',
                              style: GoogleFonts.outfit(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                            _dot(context),
                            Text(
                              (widget.movie['genre'] ?? 'Action')
                                  .toString()
                                  .split(RegExp(r'[ /]'))[0],
                              style: GoogleFonts.outfit(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            _dot(context),
                            Text(
                              widget.movie['releaseDate'] ?? 'Coming Soon',
                              style: GoogleFonts.outfit(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              ...(widget.movie['formats'] as List<dynamic>? ??
                                      [])
                                  .map(
                                    (f) => _selectionChip(
                                      context,
                                      f.toString(),
                                      false,
                                    ),
                                  ),
                              ...(widget.movie['languages'] as List<dynamic>? ??
                                      [])
                                  .map(
                                    (l) => _selectionChip(
                                      context,
                                      l.toString(),
                                      true,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(context, 'Synopsis'),
                        const SizedBox(height: 16),
                        Text(
                          widget.movie['description'] ??
                              'No synopsis available.',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(context, 'Cast'),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 110,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: cast.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 24),
                            itemBuilder: (_, i) {
                              return Column(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    child: Icon(
                                      Icons.person,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    cast[i]['name']!,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    cast[i]['role']!,
                                    style: GoogleFonts.outfit(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Dynamic Filters Container
                  Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.shadow.withValues(alpha: 0.02),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 4.5,
                      children: [
                        _filterDropdown(
                          label: selectedDate,
                          options: _generateDates(),
                          onSelected: (v) => setState(() => selectedDate = v),
                        ),
                        _filterDropdown(
                          label: selectedLanguage,
                          options: [
                            'Language',
                            ...(widget.movie['languages'] as List<dynamic>? ??
                                    [])
                                .map((e) => e.toString()),
                          ],
                          onSelected: (v) =>
                              setState(() => selectedLanguage = v),
                        ),
                        _filterDropdown(
                          label: selectedFormat,
                          options: [
                            'Format',
                            ...(widget.movie['formats'] as List<dynamic>? ?? [])
                                .map((e) => e.toString()),
                          ],
                          onSelected: (v) => setState(() => selectedFormat = v),
                        ),
                        _filterDropdown(
                          label: selectedPrice,
                          options: [
                            'Price Range',
                            'LKR 0 - LKR 200',
                            'LKR 201 - LKR 400',
                            'LKR 401 - LKR 600',
                            'LKR 601+',
                          ],
                          onSelected: (v) => setState(() => selectedPrice = v),
                        ),
                        _filterDropdown(
                          label: selectedTime,
                          options: [
                            'Show Timings',
                            'Morning (9-12)',
                            'Afternoon (12-4)',
                            'Evening (4-7)',
                            'Night (7+)',
                          ],
                          onSelected: (v) => setState(() => selectedTime = v),
                        ),
                      ],
                    ),
                  ),

                  // Showtimes Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(context, 'Showtimes'),
                        const SizedBox(height: 16),
                        if (filteredShowtimes.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'No showtimes found for selected filters',
                                style: GoogleFonts.outfit(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: filteredShowtimes.map((t) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingScreen(
                                        movieTitle:
                                            widget.movie['title'] ?? 'Movie',
                                        showtime: t['time'],
                                        showDate: t['date'],
                                        theatreName:
                                            t['theatre'] ?? 'Unknown Theatre',
                                        selectedFormat: t['format'] ?? '2D',
                                        selectedLanguage:
                                            t['language'] ?? 'English',
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.3),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      if (widget.theatreName == null)
                                        Text(
                                          t['theatre'] ?? '',
                                          style: GoogleFonts.outfit(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      Text(
                                        t['time'],
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF10B981),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        t['label'],
                                        style: GoogleFonts.outfit(
                                          color: const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  Widget _dot(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _selectionChip(BuildContext context, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 3,
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _filterDropdown({
    required String label,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) => options.map((opt) {
        return PopupMenuItem<String>(
          value: opt,
          child: Text(
            opt,
            style: GoogleFonts.outfit(
              color: opt == label
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: opt == label ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
