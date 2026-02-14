import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../services/booking_service.dart';
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
    final bookings = await BookingService.getBookings();
    if (mounted) {
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
        .where((b) => b['status'] == 'Confirmed')
        .toList();
    final cancelledBookings = _bookings
        .where((b) => b['status'] == 'Cancelled')
        .toList();

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryBlue,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: Colors.grey,
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
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              isCancelledList ? 'No Cancelled Bookings' : 'No Active Bookings',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCancelledList
                  ? "You haven't cancelled any tickets yet."
                  : "You haven't made any bookings yet.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey[500]),
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
    final bool isCancelled = booking['status'] == 'Cancelled';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: const Color(0xFF1F2937),
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
              color: const Color(0xFF8E9AAF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL AMOUNT',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'LKR ${booking['amount'] ?? '0.00'}',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: isCancelled
                          ? Colors.redAccent
                          : const Color(0xFF4ADE80),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      booking['status'] ?? 'Unknown',
                      style: GoogleFonts.outfit(
                        color: isCancelled
                            ? Colors.redAccent
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
              color: Colors.white,
              textColor: Colors.black,
              outlineColor: Colors.black,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Cancel Booking',
              onPressed: () => _confirmCancel(booking),
              color: const Color(0xFF020617),
              textColor: Colors.white,
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
        backgroundColor: Colors.white,
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
                  color: const Color(0xFF1F2937),
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
                  color: AppColors.primaryBlue,
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
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1F2937),
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
    );
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
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
