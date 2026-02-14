import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/booking_service.dart';
import '../../core/theme/app_colors.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final bookings = await BookingService.getBookings();
    if (mounted) {
      setState(() {
        _bookings = bookings.reversed.toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage All Bookings'),
        backgroundColor: const Color(0xFF020617),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
          ? Center(
              child: Text(
                'No bookings found',
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                final id = booking['id']?.toString() ?? 'N/A';
                final shortId = id.length > 6
                    ? '#${id.substring(id.length - 6)}'
                    : '#$id';
                final status = booking['status'] ?? 'Confirmed';
                final statusLower = status.toString().toLowerCase();
                final bool isCancelled =
                    statusLower == 'cancelled' ||
                    statusLower == 'cancellation requested';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAFB8B9),
                    borderRadius: BorderRadius.circular(12),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            shortId,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCancelled
                                  ? Colors.red[50]
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCancelled
                                    ? Colors.red[700]
                                    : Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Customer',
                        '${booking['name'] ?? 'User'} (${booking['email'] ?? 'Unknown'})',
                      ),
                      _buildInfoRow('Movie', booking['movie'] ?? 'N/A'),
                      _buildInfoRow('Theatre', booking['theatre'] ?? 'N/A'),
                      _buildInfoRow(
                        'Showtime',
                        '${booking['date']} @ ${booking['time']}',
                      ),
                      _buildInfoRow('Seats', booking['seats'] ?? 'N/A'),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL PAID',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'LKR ${booking['amount'] ?? '0'}',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF020617),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
