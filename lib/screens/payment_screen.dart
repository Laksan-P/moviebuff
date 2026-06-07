import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../widgets/premium_screen_stack.dart';
import 'my_bookings_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String movieTitle;
  final String theatreName;
  final String showDate;
  final String showTime;
  final int showtimeId;
  final int ticketCount;
  final String amount;
  final List<String> selectedSeats;

  const PaymentScreen({
    super.key,
    required this.movieTitle,
    required this.theatreName,
    required this.showDate,
    required this.showTime,
    required this.showtimeId,
    required this.ticketCount,
    required this.amount,
    required this.selectedSeats,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  String _paymentMethod = 'Debit Card';
  bool _agreedToPolicy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      debugPrint(
        '💰 BOOKING TOTAL: seats=${widget.ticketCount}, ticketPrice=—, subtotal=${widget.amount}, fees=0.00, total=${widget.amount}',
      );
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: scheme.surface.withValues(alpha: 0.82),
        elevation: 0,
        foregroundColor: scheme.onSurface,
      ),
      body: PremiumScreenStack(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.sizeOf(context).width < 400 ? 16 : 24,
                    24,
                    MediaQuery.sizeOf(context).width < 400 ? 16 : 24,
                    48 + bottomInset,
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Secure payment for your movie tickets',
                      style: GoogleFonts.outfit(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                          Expanded(
                            flex: 2,
                            child: _buildOrderSummaryCard(isWide: true),
                          ),
                        ],
                      )
                    else ...[
                      // Mobile Stack
                      _buildPaymentDetailsCard(),
                      const SizedBox(height: 24),
                      _buildOrderSummaryCard(isWide: false),
                    ],

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Payment Method',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
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
              controller: _cardNumberController,
              hint: 'Demo: 4532 1234 5678 9010',
              keyboardType: TextInputType.number,
              maxLength: 19,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                CardNumberFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter card number';
                }
                if (value.replaceAll(' ', '').length < 16) {
                  return 'Invalid card number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildInputField(
              'Cardholder Name',
              'Name on card',
              controller: _cardNameController,
              keyboardType: TextInputType.name,
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter cardholder name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    'Expiry Date',
                    'MM/YY',
                    controller: _expiryController,
                    hint: 'Demo: 12/25',
                    keyboardType: TextInputType.datetime,
                    maxLength: 5,
                    formatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                      ExpiryDateFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                        return 'MM/YY';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField(
                    'CVV',
                    '123',
                    controller: _cvvController,
                    hint: 'Demo: 123',
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (value.length < 3) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            // Secure Encryption Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                ),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your payment information is encrypted and secure. We never store your full card details.',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.7),
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
            FormField<bool>(
              initialValue: _agreedToPolicy,
              validator: (value) {
                if (value != true) {
                  return 'You must agree to the policy to continue';
                }
                return null;
              },
              builder: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _agreedToPolicy,
                          onChanged: (v) {
                            setState(() => _agreedToPolicy = v!);
                            state.didChange(v);
                          },
                          side: const BorderSide(color: Colors.white, width: 2),
                          checkColor: AppColors.primaryBlue,
                          fillColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return Colors.transparent;
                          }),
                        ),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'I agree to the ',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(
                                  text: 'cancellation policy',
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4),
                        child: Text(
                          state.errorText!,
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
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
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness ==
                              Brightness.dark
                          ? AppColors.cinemaGoldMuted
                          : AppColors.paymentButton,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text('Pay'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard({required bool isWide}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
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
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 32),

          _infoSection('MOVIE', widget.movieTitle),
          const SizedBox(height: 24),
          _infoSection('THEATRE', widget.theatreName),
          const SizedBox(height: 24),
          _infoSection(
            'DATE & TIME',
            '${widget.showDate} • ${widget.showTime}',
          ),
          const SizedBox(height: 24),
          _infoSection('NUMBER OF TICKETS', '${widget.ticketCount} Ticket(s)'),

          const SizedBox(height: 32),
          Divider(
            color: Theme.of(
              context,
            ).colorScheme.onSecondaryContainer.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 32),

          _priceRow('Subtotal', 'LKR ${widget.amount}'),
          const SizedBox(height: 12),
          _priceRow('Taxes & Fees', 'LKR 0.00'),

          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSecondaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.cinemaGold.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final stack = c.maxWidth < 320;
                final lblStyle = GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSecondaryContainer.withValues(alpha: 0.6),
                );
                final amtStyle = GoogleFonts.outfit(
                  fontSize: isWide ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cinemaGold,
                  letterSpacing: 0.3,
                );
                final amountText = 'LKR ${widget.amount}';
                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('TOTAL AMOUNT', style: lblStyle),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(amountText, style: amtStyle),
                      ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'TOTAL AMOUNT',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: lblStyle,
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
                            amountText,
                            maxLines: 1,
                            style: amtStyle,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSecondaryContainer.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '50% REFUND POLICY',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Cancel anytime and get 50% of your ticket price back. 50% will be deducted as cancellation fee.',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
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
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
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
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          maxLength: maxLength,
          validator: validator,
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.outfit(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
            errorStyle: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            counterText: "", // Hide the character counter
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(
            hint,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
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
            color: Theme.of(
              context,
            ).colorScheme.onSecondaryContainer.withValues(alpha: 0.6),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 340;
        final labelStyle = GoogleFonts.outfit(
          fontSize: 16,
          color: Theme.of(
            context,
          ).colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
        );
        final valueStyle = GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        );
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: labelStyle),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(value, style: valueStyle),
                ),
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
                    value,
                    maxLines: 1,
                    style: valueStyle,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String timeStr = widget.showTime;
    final String dateStr = widget.showDate;

    // Fetch current user details to ensure persistence in dashboard
    final userName = await AuthService.getUserName() ?? 'Guest';
    final userEmail = await AuthService.getUserEmail() ?? 'Unknown';

    final bookingPayload = {
      'name': userName,
      'email': userEmail,
      'movie': widget.movieTitle,
      'theatre': widget.theatreName,
      'date': dateStr,
      'time': timeStr,
      'seats': widget.selectedSeats.join(', '),
      'amount': widget.amount.toString(),
      'tickets': widget.ticketCount.toString(),
      'showtime_id': widget.showtimeId,
      'payment_method': _paymentMethod.toLowerCase().contains('credit')
          ? 'credit_card'
          : 'debit_card',
      'card_number': _cardNumberController.text.trim(),
    };

    try {
      await BookingService.saveBooking(
        Map<String, dynamic>.from(bookingPayload),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save booking: $e')),
        );
      }
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking confirmed via API.')),
    );

    if (!mounted) return;

    // Booking Confirmation Dialog
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(200),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            child: SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width < 400 ? 12 : 24,
                ),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
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
                          decoration: BoxDecoration(
                            color: Colors.greenAccent[400],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Booking Confirmed!',
                    textAlign: TextAlign.center,
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
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      'Booking saved locally and ready to view in My Bookings.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
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
                        _summaryRow(
                          'Date & Time',
                          '${widget.showDate} • ${widget.showTime}',
                        ),
                        const SizedBox(height: 12),
                        _summaryRow('Seats', widget.selectedSeats.join(', ')),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Colors.white24, height: 1),
                        ),
                        LayoutBuilder(
                          builder: (context, c) {
                            final stack = c.maxWidth < 280;
                            final amtTextStyle = GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            );
                            final lblStyle = GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.6),
                            );
                            final paid = 'LKR ${widget.amount}';
                            if (stack) {
                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Text('AMOUNT PAID', style: lblStyle),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(paid, style: amtTextStyle),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    'AMOUNT PAID',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: lblStyle,
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
                                        paid,
                                        maxLines: 1,
                                        style: amtTextStyle,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
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
                        backgroundColor: AppColors.paymentButton,
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
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 280;
        final labelWidget = Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Theme.of(
              context,
            ).colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
          ),
        );
        final valueWidget = Text(
          value,
          textAlign: narrow ? TextAlign.start : TextAlign.end,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        );
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              labelWidget,
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: valueWidget,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: labelWidget,
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: valueWidget,
                ),
              ),
            ),
          ],
        );
      },
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
        buffer.write(' '); // Add space after every 4 digits
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
