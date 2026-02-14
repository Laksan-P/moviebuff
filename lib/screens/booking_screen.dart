import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment_screen.dart';
import '../services/booking_service.dart';

class BookingScreen extends StatefulWidget {
  final String movieTitle;
  final String showtime;
  final String showDate;
  final String theatreName;
  final String selectedFormat;
  final String selectedLanguage;

  const BookingScreen({
    super.key,
    required this.movieTitle,
    required this.showtime,
    required this.showDate,
    required this.theatreName,
    this.selectedFormat = '2D',
    this.selectedLanguage = 'English',
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final List<String> _rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
  final int _cols = 8;
  final Set<String> _selectedSeats = {};
  Set<String> _bookedSeats = {};

  @override
  void initState() {
    super.initState();
    _loadBookedSeats();
  }

  Future<void> _loadBookedSeats() async {
    final seats = await BookingService.getBookedSeats(
      widget.movieTitle,
      widget.theatreName,
      widget.showDate,
      widget.showtime,
    );
    setState(() {
      _bookedSeats = seats.toSet();
    });
  }

  final double _pricePerSeat = 750.0;
  final double _bookingFee = 0.0;

  void _toggleSeat(String seat) {
    if (_bookedSeats.contains(seat)) return;
    setState(() {
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
      } else {
        _selectedSeats.add(seat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = _selectedSeats.length * _pricePerSeat;
    double total = subtotal + _bookingFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.movieTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Screen Visual and Legend Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF6D87AE),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  // Screen Visual
                  Container(
                    margin: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SCREEN',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.5),
                            letterSpacing: 2,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Seat Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _cols,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _rows.length * _cols,
                    itemBuilder: (context, index) {
                      int rowIdx = index ~/ _cols;
                      int colIdx = index % _cols;
                      String seatId = '${_rows[rowIdx]}${colIdx + 1}';

                      bool isBooked = _bookedSeats.contains(seatId);
                      bool isSelected = _selectedSeats.contains(seatId);

                      return GestureDetector(
                        onTap: () => _toggleSeat(seatId),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBooked
                                ? const Color(0xFF94A3B8)
                                : isSelected
                                ? const Color(0xFF020617)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              seatId,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected || isBooked
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),

                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Available', Colors.white),
                      const SizedBox(width: 16),
                      _buildLegendItem('Selected', const Color(0xFF020617)),
                      const SizedBox(width: 16),
                      _buildLegendItem('Booked', const Color(0xFF94A3B8)),
                    ],
                  ),
                ],
              ),
            ),

            // Booking Summary Card
            if (_selectedSeats.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF6D87AE),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Summary',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: _summaryInfo(
                            'SEATS',
                            _selectedSeats.join(', '),
                          ),
                        ),
                        Expanded(
                          child: _summaryInfo(
                            'DATE',
                            _formatDate(widget.showDate),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _summaryInfo('FORMAT', widget.selectedFormat),
                        ),
                        Expanded(
                          child: _summaryInfo(
                            'LANGUAGE',
                            widget.selectedLanguage,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 24),

                    _priceRow('Subtotal', 'LKR ${subtotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    _priceRow(
                      'Booking Fees',
                      'LKR ${_bookingFee.toStringAsFixed(2)}',
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'LKR ${total.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                movieTitle: widget.movieTitle,
                                theatreName: widget.theatreName,
                                showDate: widget.showDate,
                                showTime: widget.showtime,
                                ticketCount: _selectedSeats.length,
                                amount: total.toStringAsFixed(2),
                                selectedSeats: _selectedSeats.toList(),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006D7E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Proceed to Payment',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Select a seat to see booking summary',
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
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
      return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  Widget _summaryInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
