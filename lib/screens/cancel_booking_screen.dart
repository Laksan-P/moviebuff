import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/booking_service.dart';

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
    // Show loading or processing state if needed
    // For now, just call the service and navigate back
    await BookingService.requestCancellation(
      widget.booking['id'],
      _selectedReason ?? 'Other',
      _commentController.text,
    );

    if (!mounted) return;

    // Show success feedback and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking cancelled successfully'),
        backgroundColor: Color(0xFF4ADE80),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Parse amount to double for calculation
    double originalAmount =
        double.tryParse(widget.booking['amount'].toString()) ?? 0.0;
    double refundAmount = originalAmount * 0.5;
    double cancellationFee = originalAmount * 0.5;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Back to Bookings',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        titleSpacing: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cancel Booking',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can cancel your booking anytime with\n50% refund',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.grey[600],
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
      bottomNavigationBar: MediaQuery.of(context).size.width > 900
          ? null // Hide bottom bar in landscape (actions moved to right col)
          : _buildBottomBarMobile(),
    );
  }

  Widget _buildBookingDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF6D87AE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.booking['movie'] ?? 'Unknown Movie',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
            '#${widget.booking['id'].toString().substring(widget.booking['id'].toString().length - 6)}',
          ),

          const SizedBox(height: 32),

          // Policy Warning Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(color: Colors.redAccent.shade200, width: 4),
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPolicyPoint('Your booking will be cancelled permanently'),
                _buildPolicyPoint(
                  'You will receive 50% of your ticket price as refund',
                ),
                _buildPolicyPoint('50% cancellation fee will be deducted'),
                _buildPolicyPoint(
                  'Refund will be processed to your original payment method',
                ),
                _buildPolicyPoint('Refund is processed immediately'),
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
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedReason,
              hint: Text(
                'Select a Reason...',
                style: GoogleFonts.outfit(color: Colors.grey[600]),
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
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tell us more about your cancellation (optional)',
            hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[100], // Slightly lighter gray than card
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
                activeColor: const Color(0xFF023E5C),
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
                  color: const Color(0xFF4B5563),
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
            color: const Color(0xFF6D87AE),
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
                  color: Colors.white,
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
                valueColor: Colors.redAccent.shade100,
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 24),

              // You Will Receive Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF023E5C).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'YOU WILL RECEIVE',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LKR ${refundAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REFUND TIMELINE',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineItem(
                      'Immediate',
                      'Cancellation processed',
                      isFirst: true,
                    ),
                    _buildTimelineItem(
                      'Immediate',
                      'Refund to payment method',
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
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Note: You can cancel this booking anytime. Refund will be processed to your original payment method.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF1F2937),
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
              foregroundColor: const Color(0xFF6D87AE),
              side: const BorderSide(color: Color(0xFF6D87AE), width: 2),
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
              backgroundColor: const Color(0xFF023E5C),
              disabledBackgroundColor: Colors.grey[300],
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
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBarMobile() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(child: _buildActionButtons()),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.9),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: valueColor ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String time,
    String title, {
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
              color: Colors.black.withValues(alpha: 0.7),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 24,
                color: Colors.black.withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              time,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }
}
