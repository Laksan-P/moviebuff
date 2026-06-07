import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../services/api_mappers.dart';
import '../services/api_service.dart';
import '../services/booking_service.dart';
import '../utils/text_safety.dart';
import '../widgets/premium_screen_stack.dart';

class CancelBookingScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const CancelBookingScreen({super.key, required this.booking});

  @override
  State<CancelBookingScreen> createState() => _CancelBookingScreenState();
}

class _CancelBookingScreenState extends State<CancelBookingScreen> {
  String? _selectedReason;
  bool _agreedToPolicy = false;
  final TextEditingController _commentController = TextEditingController();

  final List<String> _cancellationReasons = [
    'Change of plans',
    'Booked by mistake',
    'Found a better showtime',
    'Health issues',
    'Other',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _processCancellation() async {
    if (!ApiMappers.canRequestCancellation(widget.booking)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A cancellation request is already pending for this booking.',
          ),
        ),
      );
      Navigator.pop(context);
      return;
    }

    try {
      await BookingService.requestCancellation(
        widget.booking['id'],
        _selectedReason ?? 'Other',
        _commentController.text,
        booking: widget.booking,
      );
      await BookingService.getBookings();
      BookingService.notifyBookingsChanged();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Cancellation request submitted. Awaiting admin review.',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit cancellation: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parse amount to double for calculation
    double originalAmount =
        double.tryParse(widget.booking['amount'].toString()) ?? 0.0;
    double refundAmount = originalAmount * 0.5;
    double cancellationFee = originalAmount * 0.5;

    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: scheme.surface.withValues(alpha: 0.82),
        elevation: 0,
        foregroundColor: scheme.onSurface,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: scheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Back to Bookings',
          style: GoogleFonts.outfit(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        titleSpacing: 0,
      ),
      body: PremiumScreenStack(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    24 + bottomInset + (constraints.maxWidth > 900 ? 0 : 100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      'Cancel Booking',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can cancel your booking anytime with\n50% refund',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Details & Form
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildBookingDetailsCard(),
                                const SizedBox(height: 24),
                                _buildCancellationForm(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          // Right Column: Summary & Actions
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildRefundSummaryCard(
                                  originalAmount,
                                  cancellationFee,
                                  refundAmount,
                                ),
                                const SizedBox(height: 24),
                                _buildActionButtons(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      // Mobile Stack
                      _buildBookingDetailsCard(),
                      const SizedBox(height: 32),
                      _buildCancellationForm(),
                      const SizedBox(height: 32),
                      _buildRefundSummaryCard(
                        originalAmount,
                        cancellationFee,
                        refundAmount,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
        ),
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width > 900
          ? null
          : _buildBottomBarMobile(),
    );
  }

  Widget _buildBookingDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.booking['movie'] ?? 'Unknown Movie',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Theatre', widget.booking['theatre'] ?? 'N/A'),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Date & Time',
            '${widget.booking['date']} - ${widget.booking['time']}',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Number of Tickets',
            widget.booking['tickets']?.toString() ?? '1',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Booking ID',
            TextSafety.safeBookingIdSuffix(widget.booking['id']),
          ),

          const SizedBox(height: 32),

          // Policy Warning Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.35
                        : 0.45,
                  ),
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before You Cancel',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPolicyPoint(
                  'Your booking will be cancelled permanently',
                  context,
                ),
                _buildPolicyPoint(
                  'You will receive 50% of your ticket price as refund',
                  context,
                ),
                _buildPolicyPoint(
                  '50% cancellation fee will be deducted',
                  context,
                ),
                _buildPolicyPoint(
                  'Refund will be processed to your original payment method',
                  context,
                ),
                _buildPolicyPoint('Refund is processed immediately', context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reason Selection
        Text(
          'Reason for Cancellation',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedReason,
              hint: Text(
                'Select a Reason...',
                style: GoogleFonts.outfit(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: _cancellationReasons.map((String reason) {
                return DropdownMenuItem<String>(
                  value: reason,
                  child: Text(reason, style: GoogleFonts.outfit()),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedReason = newValue;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Comment Box
        Text(
          'Additional Comments (Optional)',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tell us more about your cancellation (optional)',
            hintStyle: GoogleFonts.outfit(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5), // Slightly lighter gray than card
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),

        const SizedBox(height: 24),

        // Agreement Checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _agreedToPolicy,
                activeColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (value) {
                  setState(() {
                    _agreedToPolicy = value ?? false;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'I understand and agree to the 50% refund policy. I acknowledge that 50% of my ticket price will be deducted as cancellation fee.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRefundSummaryCard(
    double originalAmount,
    double cancellationFee,
    double refundAmount,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Refund Summary',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              _buildSummaryRow(
                'Original Amount',
                'LKR ${originalAmount.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                'Cancellation Fee (50%)',
                '-LKR ${cancellationFee.toStringAsFixed(2)}',
                valueColor: Theme.of(context).colorScheme.error,
              ),

              const SizedBox(height: 24),
              Divider(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withValues(alpha: 0.2),
              ),
              const SizedBox(height: 24),

              // You Will Receive Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'YOU WILL RECEIVE',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        'LKR ${refundAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cinemaGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Timeline
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REFUND TIMELINE',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineItem(
                      'Immediate',
                      'Cancellation processed',
                      context,
                      isFirst: true,
                    ),
                    _buildTimelineItem(
                      'Immediate',
                      'Refund to payment method',
                      context,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Note: You can cancel this booking anytime. Refund will be processed to your original payment method.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Keep Booking',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (_agreedToPolicy && _selectedReason != null)
                ? _processCancellation
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              disabledBackgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Confirm Cancellation',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBarMobile() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(color: scheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(child: _buildActionButtons()),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return LayoutBuilder(
      builder: (context, c) {
        final stack = c.maxWidth < 360;
        final labelStyle = GoogleFonts.outfit(
          color: Theme.of(
            context,
          ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
          fontSize: 15,
        );
        final valueStyle = GoogleFonts.outfit(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        );
        if (stack) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: labelStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle,
                ),
              ],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '$label:',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ),
            Expanded(
              child: Text(
                value,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPolicyPoint(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: Theme.of(context)
                    .colorScheme
                    .onErrorContainer
                    .withValues(alpha: 0.92),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return LayoutBuilder(
      builder: (context, c) {
        final dense = c.maxWidth < 340;
        final baseStyle = GoogleFonts.outfit(
          color: Theme.of(context)
              .colorScheme
              .onPrimaryContainer
              .withValues(alpha: 0.7),
          fontSize: 15,
        );
        final valueBase = GoogleFonts.outfit(
          color: valueColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        );
        if (dense) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(label, style: baseStyle),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(value, style: valueBase),
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: baseStyle,
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
                      textAlign: TextAlign.end,
                      style: valueBase,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem(
    String time,
    String title,
    BuildContext context, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              Icons.check,
              size: 16,
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 24,
                color: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
