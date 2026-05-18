import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/movie_provider.dart';
import '../../services/admin_catalog_service.dart';
import 'admin_movies_screen.dart';
import 'admin_showtimes_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_theatres_screen.dart';
import 'admin_cancellations_screen.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../providers/connectivity_provider.dart';
import '../login_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../utils/text_safety.dart';
import '../../widgets/cinematic_background.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _theatres = [];
  List<Map<String, dynamic>> _movies = [];
  bool _bookingsLoading = true;
  bool _catalogueCountsLoading = true;
  MovieProvider? _movieProv;

  // Stats
  int _totalBookings = 0;
  int _confirmedBookings = 0;
  double _totalRevenue = 0;
  int _cancellations = 0;
  double _refundedAmount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _movieProv = context.read<MovieProvider>();
      _movieProv!.addListener(_onCatalogueChanged);
      _loadBookings();
      _onCatalogueChanged();
    });
  }

  @override
  void dispose() {
    _movieProv?.removeListener(_onCatalogueChanged);
    super.dispose();
  }

  void _onCatalogueChanged() {
    final prov = _movieProv;
    if (prov == null || !mounted) return;
    if (!prov.catalogueReady) {
      if (!_catalogueCountsLoading) {
        setState(() => _catalogueCountsLoading = true);
      }
      return;
    }
    _syncCatalogueCounts(prov.movies);
  }

  Future<void> _syncCatalogueCounts(
    List<Map<String, dynamic>> catalogueMovies,
  ) async {
    final movies =
        await AdminCatalogService.mergeMoviesForAdmin(catalogueMovies);
    final theatres =
        await AdminCatalogService.mergeTheatresForAdmin(catalogueMovies);
    if (!mounted) return;
    setState(() {
      _movies = movies;
      _theatres = theatres;
      _catalogueCountsLoading = false;
    });
  }

  Future<void> _loadBookings() async {
    final bookings = await BookingService.getBookings();

    int total = 0;
    int confirmed = 0;
    double revenue = 0;
    int cancelled = 0;
    double refunded = 0;
    for (var b in bookings) {
      total++;
      final rawAmt =
          b['amount'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
      final price = double.tryParse(rawAmt) ?? 0.0;

      if (b['status'] == 'Confirmed') {
        confirmed++;
        revenue += price;
      } else if (b['status'] == 'Cancelled' ||
          b['status'] == 'Cancellation Requested') {
        cancelled++;
        final cancellationFee = price * 0.5;
        revenue += cancellationFee;
        refunded += price * 0.5;
      }
    }

    if (mounted) {
      setState(() {
        _bookings = bookings.reversed.toList();
        _totalBookings = total;
        _confirmedBookings = confirmed;
        _totalRevenue = revenue;
        _cancellations = cancelled;
        _refundedAmount = refunded;
        _bookingsLoading = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _bookingsLoading = true;
      _catalogueCountsLoading = true;
    });
    await _loadBookings();
    if (!mounted) return;
    final prov = context.read<MovieProvider>();
    await prov.load(forceRefresh: true);
    if (!mounted) return;
    await _syncCatalogueCounts(prov.movies);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<MovieProvider>();

    final now = DateTime.now();
    final dateStr =
        '${_getMonth(now.month)} ${now.day}, ${now.year} ${_formatTime(now)}';
    final scheme = Theme.of(context).colorScheme;
    final conn = context.watch<ConnectivityProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Control center',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: scheme.surface.withValues(alpha: 0.82),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Logout',
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CinematicBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'MovieBuff Admin',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Overview · last updated $dateStr',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _adminChip(
                      context,
                      conn.isOnline ? Icons.cloud_done_outlined : Icons.cloud_off,
                      conn.isOnline ? 'Network OK' : 'Offline mode',
                      conn.isOnline ? scheme.primary : scheme.error,
                    ),
                    _adminChip(
                      context,
                      Icons.movie_creation_outlined,
                      _catalogueCountsLoading
                          ? 'Movies…'
                          : '${_movies.length} movies',
                      scheme.secondary,
                    ),
                    _adminChip(
                      context,
                      Icons.theater_comedy_outlined,
                      _catalogueCountsLoading
                          ? 'Theatres…'
                          : '${_theatres.length} theatres',
                      scheme.tertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildStatCardFullWidth(
                  title: 'TOTAL BOOKINGS',
                  value: _bookingsLoading ? '…' : '$_totalBookings',
                  subValue: _bookingsLoading
                      ? 'Loading bookings…'
                      : 'Confirmed: $_confirmedBookings',
                ),
                const SizedBox(height: 14),
                _buildStatCardFullWidth(
                  title: 'TOTAL REVENUE',
                  value: _bookingsLoading
                      ? '…'
                      : 'LKR ${_totalRevenue.toStringAsFixed(2)}',
                  isRevenue: true,
                ),
                const SizedBox(height: 14),
                _buildStatCardFullWidth(
                  title: 'CANCELLATIONS',
                  value: _bookingsLoading ? '…' : '$_cancellations',
                  subValue: _bookingsLoading
                      ? 'Loading…'
                      : 'Refunded: LKR ${_refundedAmount.asFixed(2)}',
                  subValueColor: scheme.error,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminCancellationsScreen(),
                      ),
                    ).then((_) => _refreshDashboard());
                  },
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isWide = constraints.maxWidth > 1100;

                    if (isWide) {
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildTheatreSection()),
                              const SizedBox(width: 20),
                              Expanded(child: _buildMovieSection()),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildRecentBookings(),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildTheatreSection(),
                          const SizedBox(height: 20),
                          _buildMovieSection(),
                          const SizedBox(height: 20),
                          _buildRecentBookings(),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 28),
                _buildQuickActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminChip(
    BuildContext context,
    IconData icon,
    String label,
    Color accent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: scheme.surface.withValues(alpha: 0.88),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick actions',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton('Manage Theatres', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminTheatresScreen()),
            ).then((_) {
              _loadBookings();
              _onCatalogueChanged();
            });
          }),
          const SizedBox(height: 12),
          _buildActionButton('Manage Showtimes', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminShowtimesScreen()),
            );
          }),
          const SizedBox(height: 12),
          _buildActionButton('Pending Cancellations', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminCancellationsScreen(),
              ),
            ).then((_) {
              _loadBookings();
              _onCatalogueChanged();
            });
          }),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildStatCardFullWidth({
    required String title,
    required String value,
    String? subValue,
    Color? subValueColor,
    bool isRevenue = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:
            double.infinity, // Ensures the card takes the full available width
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 1.1,
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.1,
                color: isRevenue
                    ? AppColors.cinemaGold
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (subValue != null) ...[
              const SizedBox(height: 8),
              Text(
                subValue,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color:
                      subValueColor ?? Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTheatreSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Theatre Management',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminTheatresScreen(),
                    ),
                  ).then((_) {
              _loadBookings();
              _onCatalogueChanged();
            });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All →',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._theatres.take(3).map((t) {
            return Column(
              children: [
                _buildListItem(
                  TextSafety.safeShortText(t['name']?.toString(), 200,
                      fallback: 'Theatre',),
                  TextSafety.safeShortText(t['location']?.toString(), 240,
                      fallback: 'N/A',),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminTheatresScreen(),
                  ),
                ).then((_) {
              _loadBookings();
              _onCatalogueChanged();
            });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Manage Theatres'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Movie Management',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminMoviesScreen(),
                    ),
                  ).then((_) {
              _loadBookings();
              _onCatalogueChanged();
            });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All →',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._movies.take(3).map((m) {
            return Column(
              children: [
                _buildListItem(
                  TextSafety.safeShortText(
                      m['title']?.toString(), 200,
                      fallback: 'Unknown Movie',),
                  TextSafety.safeShortText(
                      m['genre']?.toString(), 120,
                      fallback: 'N/A',),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminMoviesScreen()),
                ).then((_) {
              _loadBookings();
              _onCatalogueChanged();
            });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Manage Movies'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Bookings',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminBookingsScreen(),
                    ),
                  );
                },
                child: Text(
                  'View All →',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Horizontal Scrollable Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    SizedBox(width: 100, child: _buildTableHead('BOOKING ID')),
                    SizedBox(width: 180, child: _buildTableHead('CUSTOMER')),
                    SizedBox(width: 150, child: _buildTableHead('MOVIE')),
                    SizedBox(width: 100, child: _buildTableHead('TIME')),
                    SizedBox(width: 150, child: _buildTableHead('THEATRE')),
                    SizedBox(width: 80, child: _buildTableHead('SEATS')),
                    SizedBox(width: 120, child: _buildTableHead('AMOUNT')),
                    SizedBox(width: 100, child: _buildTableHead('STATUS')),
                  ],
                ),
                const Divider(
                  height: 24,
                  color: Colors
                      .transparent, // Using transparent as the surface provides enough separation or use outline
                ),

                // Data Rows
                ..._bookings.take(5).map((booking) {
                  final id = TextSafety.safeBookingIdSuffix(booking['id']);
                  final name = (booking['name'] ?? 'User').toString();
                  final email = (booking['email'] ?? 'Unknown').toString();
                  final movie = (booking['movie'] ?? 'Unknown').toString();
                  final time = (booking['time'] ?? 'N/A').toString();
                  final theatre = (booking['theatre'] ?? 'N/A').toString();
                  final seats = (booking['seats'] ?? []).toString();
                  final amount = (booking['amount'] ?? 'LKR 0').toString();
                  final status = (booking['status'] ?? 'Pending').toString();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        // ID
                        SizedBox(
                          width: 100,
                          child: Text(
                            id,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        // CUSTOMER
                        SizedBox(
                          width: 180,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                email,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // MOVIE
                        SizedBox(
                          width: 150,
                          child: Text(
                            movie,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // TIME
                        SizedBox(
                          width: 100,
                          child: Text(
                            time,
                            style: GoogleFonts.outfit(fontSize: 13),
                          ),
                        ),
                        // THEATRE
                        SizedBox(
                          width: 150,
                          child: Text(
                            theatre,
                            style: GoogleFonts.outfit(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // SEATS
                        SizedBox(
                          width: 80,
                          child: Text(
                            seats,
                            style: GoogleFonts.outfit(fontSize: 13),
                          ),
                        ),
                        // AMOUNT
                        SizedBox(
                          width: 120,
                          child: Text(
                            amount,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        // STATUS
                        SizedBox(
                          width: 100,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'Confirmed'
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: status == 'Confirmed'
                                    ? AppColors.success
                                    : Theme.of(context).colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          if (_bookings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No bookings yet'),
            ),
        ],
      ),
    );
  }

  Widget _buildListItem(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHead(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
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
    return months[month - 1];
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 || dt.hour == 12 ? 12 : dt.hour % 12;
    final amPm = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }
}

extension DoubleExt on double {
  String asFixed(int factionDigits) => toStringAsFixed(factionDigits);
}
