import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/booking_service.dart';
import 'admin_movies_screen.dart';
import 'admin_showtimes_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_theatres_screen.dart';
import 'admin_cancellations_screen.dart';
import '../../services/auth_service.dart';
import '../../services/movie_service.dart';
import '../../services/theatre_service.dart';
import '../login_screen.dart';
import '../../core/theme/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _theatres = [];
  List<Map<String, dynamic>> _movies = [];
  bool _isLoading = true;

  // Stats
  int _totalBookings = 0;
  int _confirmedBookings = 0;
  double _totalRevenue = 0;
  int _cancellations = 0;
  double _refundedAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final bookings = await BookingService.getBookings();
    final movies = await MovieService.getMovies();
    final theatres = await TheatreService.getTheatres();

    int total = 0;
    int confirmed = 0;
    double revenue = 0;
    int cancelled = 0;
    double refunded = 0;
    for (var b in bookings) {
      total++;
      // Parse amount safely: remove non-numeric characters (except dot)
      String rawAmt = b['amount'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
      double price = double.tryParse(rawAmt) ?? 0.0;

      if (b['status'] == 'Confirmed') {
        confirmed++;
        revenue += price;
      } else if (b['status'] == 'Cancelled' ||
          b['status'] == 'Cancellation Requested') {
        cancelled++;
        // 50% is retained as revenue, 50% is refunded
        double cancellationFee = price * 0.5;
        revenue += cancellationFee;
        refunded += price * 0.5;
      }
    }

    if (mounted) {
      setState(() {
        _bookings = bookings.reversed.toList();
        _movies = movies;
        _theatres = theatres;
        _totalBookings = total;
        _confirmedBookings = confirmed;
        _totalRevenue = revenue;
        _cancellations = cancelled;
        _refundedAmount = refunded;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
    final dateStr =
        '${_getMonth(now.month)} ${now.day}, ${now.year} ${_formatTime(now)}';

    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface, // Adaptive background
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadDashboardData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              // Show confirmation dialog
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
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Force children to fill width
          children: [
            // Header
            Text(
              'Admin Dashboard',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Here's your business overview. Last updated: $dateStr",
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),

            // --- STATS SECTION: FORCED VERTICAL STACK (1 COLUMN) ---
            _buildStatCardFullWidth(
              title: 'TOTAL BOOKINGS',
              value: '$_totalBookings',
              subValue: 'Confirmed: $_confirmedBookings',
            ),
            const SizedBox(height: 16),
            _buildStatCardFullWidth(
              title: 'TOTAL REVENUE',
              value: 'LKR ${_totalRevenue.toStringAsFixed(2)}',
              isRevenue: true,
            ),
            const SizedBox(height: 16),
            _buildStatCardFullWidth(
              title: 'CANCELLATIONS',
              value: '$_cancellations',
              subValue: 'Refunded: LKR ${_refundedAmount.asFixed(2)}',
              subValueColor: Colors.redAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminCancellationsScreen(),
                  ),
                ).then((_) => _loadDashboardData());
              },
            ),

            // --------------------------------------------------------
            const SizedBox(height: 32),

            // Middle Sections (Dynamic Layout)
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
                          const SizedBox(width: 24),
                          Expanded(child: _buildMovieSection()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildRecentBookings(),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildTheatreSection(),
                      const SizedBox(height: 24),
                      _buildMovieSection(),
                      const SizedBox(height: 24),
                      _buildRecentBookings(),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 32),

            // Quick Actions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Admin Actions',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildActionButton('Manage Theatres', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminTheatresScreen(),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      _buildActionButton('Manage Showtimes', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminShowtimesScreen(),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      _buildActionButton('Pending Cancellations', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminCancellationsScreen(),
                          ),
                        ).then((_) => _loadDashboardData());
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer.withValues(alpha: 0.6),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: isRevenue
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            if (subValue != null) ...[
              const SizedBox(height: 8),
              Text(
                subValue,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
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
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Theatre Management',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminTheatresScreen(),
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
          ..._theatres.take(3).map((t) {
            return Column(
              children: [
                _buildListItem(t['name'] as String, t['location'] as String),
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
                );
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
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Movie Management',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminMoviesScreen(),
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
          ..._movies.take(3).map((m) {
            return Column(
              children: [
                _buildListItem(
                  m['title'] ?? 'Unknown Movie',
                  m['genre'] ?? 'N/A',
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
                );
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
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
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
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
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
                  final id =
                      '#${(booking['id'] as String).substring(booking['id'].length - 6)}';
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
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
