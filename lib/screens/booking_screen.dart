import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
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
    if (_bookedSeats.contains(seat)) return; // If seat is booked, do nothing
    final hadNoSelection = _selectedSeats.isEmpty;
    setState(() {
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
      } else {
        _selectedSeats.add(seat);
      }
    });
    if (hadNoSelection && _selectedSeats.isNotEmpty) {
      _debugBookingTotals();
    }
  }

  void _debugBookingTotals() {
    final subtotal = _selectedSeats.length * _pricePerSeat;
    final total = subtotal + _bookingFee;
    debugPrint(
      '💰 BOOKING TOTAL: seats=${_selectedSeats.length}, ticketPrice=$_pricePerSeat, subtotal=${subtotal.toStringAsFixed(2)}, fees=${_bookingFee.toStringAsFixed(2)}, total=${total.toStringAsFixed(2)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = _selectedSeats.length * _pricePerSeat;
    double total = subtotal + _bookingFee;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                color: Theme.of(context).colorScheme.primaryContainer,
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
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SCREEN',
                          style: GoogleFonts.outfit(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.5),
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
                                ? (isDark
                                      ? AppColors.seatBookedDark
                                      : AppColors.seatBooked)
                                : isSelected
                                ? (isDark
                                      ? AppColors.seatSelectedDark
                                      : AppColors.seatSelected)
                                : (isDark
                                      ? AppColors.seatAvailableDark
                                      : AppColors.seatAvailable),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.seatBorderDark
                                  : AppColors.seatBorder,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              seatId,
                              style: TextStyle(
                                fontSize: 10,
                                color: isBooked
                                    ? (isDark ? Colors.white38 : Colors.black38)
                                    : isSelected
                                    ? (isDark ? Colors.black : Colors.white)
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
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

                  // Legend (wraps on narrow screens)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildLegendItem(
                        'Available',
                        isDark
                            ? AppColors.seatAvailableDark
                            : AppColors.seatAvailable,
                        isDark
                            ? AppColors.seatBorderDark
                            : AppColors.seatBorder,
                      ),
                      _buildLegendItem(
                        'Selected',
                        isDark
                            ? AppColors.seatSelectedDark
                            : AppColors.seatSelected,
                        Colors.transparent,
                      ),
                      _buildLegendItem(
                        'Booked',
                        isDark
                            ? AppColors.seatBookedDark
                            : AppColors.seatBooked,
                        Colors.transparent,
                      ),
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
                  color: isDark
                      ? AppColors.bookingSummaryBackgroundDark
                      : AppColors.bookingSummaryBackground,
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

                    _moneyRow(
                      label: 'Subtotal',
                      amountLabel: 'LKR ${subtotal.toStringAsFixed(2)}',
                      labelStyle: GoogleFonts.outfit(
                        fontSize: 15,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                      amountStyle: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _moneyRow(
                      label: 'Booking Fees',
                      amountLabel: 'LKR ${_bookingFee.toStringAsFixed(2)}',
                      labelStyle: GoogleFonts.outfit(
                        fontSize: 15,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                      amountStyle: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),

                    const SizedBox(height: 24),
                    _moneyRow(
                      label: 'Total',
                      amountLabel: 'LKR ${total.toStringAsFixed(2)}',
                      labelStyle: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      amountStyle: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer,
                      ),
                      minWidthForRow: 340,
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _debugBookingTotals();
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
                          backgroundColor: isDark
                              ? AppColors.paymentButtonDark
                              : AppColors.paymentButton,
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Label + money: full amount always visible (FittedBox / stacked on narrow).
  Widget _moneyRow({
    required String label,
    required String amountLabel,
    required TextStyle labelStyle,
    required TextStyle amountStyle,
    double minWidthForRow = 280,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumn = constraints.maxWidth < minWidthForRow;
        if (useColumn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: labelStyle),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(amountLabel, style: amountStyle),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    amountLabel,
                    maxLines: 1,
                    style: amountStyle,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color, [Color? borderColor]) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: borderColor != null ? Border.all(color: borderColor) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
