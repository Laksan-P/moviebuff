import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import 'cancel_booking_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final userEmail = await AuthService.getUserEmail();
    final bookings = await BookingService.getBookings(userEmail: userEmail);
    if (mounted) {
      debugPrint('📑 MY BOOKINGS - Loaded ${bookings.length} bookings');
      for (var b in bookings) {
        debugPrint(
          '  - ${b['movie']} (ID: ${b['id']}, Status: ${b['status']})',
        );
      }
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeBookings = _bookings
        .where(
          (b) => b['status'].toString().trim().toLowerCase() == 'confirmed',
        )
        .toList();
    final cancelledBookings = _bookings.where((b) {
      final s = b['status'].toString().trim().toLowerCase();
      return s == 'cancelled' || s == 'cancellation requested';
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Active Bookings (${activeBookings.length})'),
            Tab(text: 'Cancelled (${cancelledBookings.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingList(activeBookings, false),
                _buildBookingList(cancelledBookings, true),
              ],
            ),
    );
  }

  Widget _buildBookingList(
    List<Map<String, dynamic>> bookings,
    bool isCancelledList,
  ) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 24),
            Text(
              isCancelledList ? 'No Cancelled Bookings' : 'No Active Bookings',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCancelledList
                  ? "You haven't cancelled any tickets yet."
                  : "You haven't made any bookings yet.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'Unknown';
    final statusLower = status.toLowerCase();
    final bool isCancelled =
        statusLower == 'cancelled' || statusLower == 'cancellation requested';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking['movie'] ?? 'Unknown Movie',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Theatre:', booking['theatre'] ?? 'N/A'),
          _buildInfoRow('Date:', booking['date'] ?? 'N/A'),
          _buildInfoRow('Time:', booking['time'] ?? 'N/A'),
          _buildInfoRow('Tickets:', booking['tickets'] ?? '1'),
          _buildInfoRow('Booking Date:', booking['bookingDate'] ?? 'N/A'),
          const SizedBox(height: 20),
          // Total Amount Gray Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL AMOUNT',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer.withValues(alpha: 0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'LKR ${booking['amount'] ?? '0.00'}',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: status.toLowerCase() == 'cancelled'
                          ? Colors.redAccent
                          : status.toLowerCase() == 'cancellation requested'
                          ? Colors.orangeAccent
                          : const Color(0xFF4ADE80),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status.toLowerCase() == 'cancellation requested'
                          ? 'PENDING REFUND'
                          : status.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: status.toLowerCase() == 'cancelled'
                            ? Colors.redAccent
                            : status.toLowerCase() == 'cancellation requested'
                            ? Colors.orangeAccent
                            : const Color(0xFF4ADE80),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isCancelled) ...[
            const SizedBox(height: 20),
            CustomButton(
              text: 'View Details',
              onPressed: () => _showBookingDetails(booking),
              isOutlined: true,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Cancel Booking',
              onPressed: () => _confirmCancel(booking),
              color: Theme.of(context).colorScheme.errorContainer,
              textColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ],
        ],
      ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ticket Details',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailItem('Movie', booking['movie'] ?? 'Unknown'),
              _buildDetailItem('Theatre', booking['theatre'] ?? 'N/A'),
              _buildDetailItem(
                'Date & Time',
                '${booking['date']} at ${booking['time']}',
              ),
              _buildDetailItem(
                'Tickets',
                booking['tickets']?.toString() ?? '1',
              ),
              _buildDetailItem('Seats', booking['seats'] ?? 'N/A'),
              _buildDetailItem('Format', booking['format'] ?? '2D'),
              _buildDetailItem('Language', booking['language'] ?? 'English'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Close',
                  onPressed: () => Navigator.pop(context),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(Map<String, dynamic> booking) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CancelBookingScreen(booking: booking)),
    ).then((_) => _loadBookings());
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
