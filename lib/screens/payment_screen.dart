import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import 'my_bookings_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String movieTitle;
  final String theatreName;
  final String dateAndTime;
  final int ticketCount;
  final String amount;
  final List<String> selectedSeats;

  const PaymentScreen({
    super.key,
    required this.movieTitle,
    required this.theatreName,
    required this.dateAndTime,
    required this.ticketCount,
    required this.amount,
    required this.selectedSeats,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _paymentMethod = 'Debit Card';
  bool _agreedToPolicy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete Your\nPayment',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Secure payment for your movie tickets',
                      style: GoogleFonts.outfit(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Payment Details
                          Expanded(flex: 3, child: _buildPaymentDetailsCard()),
                          const SizedBox(width: 32),
                          // Right: Order Summary
                          Expanded(flex: 2, child: _buildOrderSummaryCard()),
                        ],
                      )
                    else ...[
                      // Mobile Stack
                      _buildPaymentDetailsCard(),
                      const SizedBox(height: 24),
                      _buildOrderSummaryCard(),
                    ],

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF6D87AE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Payment Method',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _buildRadioOption('Debit Card'),
          _buildRadioOption('Credit Card'),

          const SizedBox(height: 24),
          _buildInputField(
            'Card Number',
            '1234 5678 9012 3456',
            hint: 'Demo: 4532 1234 5678 9010',
            keyboardType: TextInputType.number,
            maxLength: 19,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              CardNumberFormatter(),
            ],
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'Cardholder Name',
            'Name on card',
            keyboardType: TextInputType.name,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  'Expiry Date',
                  'MM/YY',
                  hint: 'Demo: 12/25',
                  keyboardType: TextInputType.datetime,
                  maxLength: 5,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                    ExpiryDateFormatter(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  'CVV',
                  '123',
                  hint: 'Demo: 123',
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          // Secure Encryption Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SECURE ENCRYPTION',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your payment information is encrypted and secure. We never store your full card details.',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.black,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Row(
            children: [
              Checkbox(
                value: _agreedToPolicy,
                onChanged: (v) => setState(() => _agreedToPolicy = v!),
                activeColor: const Color(0xFF006D7E),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: 'cancellation policy',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(
                        text:
                            ' which allows 50% refund deduction as cancellation fee',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _agreedToPolicy ? _processPayment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF023E5C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Pay'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF6D87AE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          _infoSection('MOVIE', widget.movieTitle),
          const SizedBox(height: 24),
          _infoSection('THEATRE', widget.theatreName),
          const SizedBox(height: 24),
          _infoSection('DATE & TIME', widget.dateAndTime),
          const SizedBox(height: 24),
          _infoSection('NUMBER OF TICKETS', '${widget.ticketCount} Ticket(s)'),

          const SizedBox(height: 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 32),

          _priceRow('Subtotal', 'LKR ${widget.amount}'),
          const SizedBox(height: 12),
          _priceRow('Taxes & Fees', 'LKR 0.00'),

          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL AMOUNT',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  'LKR ${widget.amount}',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      '50% REFUND POLICY',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Cancel anytime and get 50% of your ticket price back. 50% will be deducted as cancellation fee.',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String value) {
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              _paymentMethod == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.white,
                fontWeight: _paymentMethod == value
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String placeholder, {
    String? hint,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? formatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          keyboardType: keyboardType,
          inputFormatters: formatters,
          maxLength: maxLength,
          style: GoogleFonts.outfit(color: Colors.black),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.outfit(color: Colors.black45),
            filled: true,
            fillColor: const Color(0xFFD1D5DB).withValues(alpha: 0.8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            counterText: "", // Hide the character counter
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(
            hint,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoSection(String label, String value) {
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
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
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
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _processPayment() async {
    final dateParts = widget.dateAndTime.split(' ');
    final String timeStr = dateParts.length >= 5
        ? '${dateParts[3]} ${dateParts[4]}'
        : 'N/A';
    final String dateStr = dateParts.length >= 3
        ? '${dateParts[0]} ${dateParts[1]} ${dateParts[2]}'
        : 'Feb 16, 2026';

    // Fetch current user details to ensure persistence in dashboard
    final userName = await AuthService.getUserName() ?? 'Guest';
    final userEmail = await AuthService.getUserEmail() ?? 'Unknown';

    // Save to persistence
    await BookingService.saveBooking({
      'name': userName,
      'email': userEmail,
      'movie': widget.movieTitle,
      'theatre': widget.theatreName,
      'date': dateStr,
      'time': timeStr,
      'seats': widget.selectedSeats.join(', '),
      'amount': widget.amount.toString(),
      'tickets': widget.ticketCount.toString(),
      'format': 'IMAX',
      'language': 'English',
    });

    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF6D87AE),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Checkmark Icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Booking Confirmed!',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your tickets have been successfully\nbooked.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Summary Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _summaryRow('Movie', widget.movieTitle),
                        const SizedBox(height: 12),
                        _summaryRow('Theatre', widget.theatreName),
                        const SizedBox(height: 12),
                        _summaryRow('Date & Time', widget.dateAndTime),
                        const SizedBox(height: 12),
                        _summaryRow('Seats', widget.selectedSeats.join(', ')),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Colors.white24, height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'AMOUNT PAID',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              'LKR ${widget.amount}',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const MyBookingsScreen(),
                          ),
                          (route) => route.isFirst,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF023E5C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Go to My Bookings',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.isEmpty) return newValue.copyWith(text: '');

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonSpaceLength = i + 1;
      if (nonSpaceLength % 4 == 0 &&
          nonSpaceLength != 16 &&
          i != text.length - 1) {
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll('/', '');

    // Handle deletion
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    if (text.isEmpty) return newValue.copyWith(text: '');

    // Month Validation
    if (text.length == 1) {
      int firstDigit = int.parse(text);
      if (firstDigit > 1) {
        // If user types 2-9, auto-format as 0X/
        var newText = '0$text/';
        return newValue.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    } else if (text.length >= 2) {
      int month = int.parse(text.substring(0, 2));
      if (month > 12) {
        // Revert to old value if month is invalid
        return oldValue;
      }
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var index = i + 1;
      if (index == 2 && i != text.length - 1) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
