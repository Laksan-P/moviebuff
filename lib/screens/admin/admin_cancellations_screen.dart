import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/booking_service.dart';

class AdminCancellationsScreen extends StatefulWidget {
  const AdminCancellationsScreen({super.key});

  @override
  State<AdminCancellationsScreen> createState() =>
      _AdminCancellationsScreenState();
}

class _AdminCancellationsScreenState extends State<AdminCancellationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _fullHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCancellations();
  }

  Future<void> _loadCancellations() async {
    final allBookings = await BookingService.getBookings();
    if (mounted) {
      setState(() {
        _pendingRequests = allBookings
            .where(
              (b) =>
                  b['status'].toString().trim().toLowerCase() ==
                  'cancellation requested',
            )
            .toList();
        _fullHistory = allBookings
            .where(
              (b) => b['status'].toString().trim().toLowerCase() == 'cancelled',
            )
            .toList();
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Back to Dashboard',
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cancellation\nManagement',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review and manage booking cancellations',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorWeight: 3,
                    labelColor: Theme.of(context).colorScheme.onSurface,
                    unselectedLabelColor: Theme.of(context).colorScheme.outline,
                    labelStyle: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    tabs: [
                      Tab(
                        text: 'Pending Requests (${_pendingRequests.length})',
                      ),
                      Tab(text: 'Full History (${_fullHistory.length})'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildPendingList(), _buildHistoryList()],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState('No pending cancellation requests');
    }

    return ListView.separated(
      itemCount: _pendingRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = _pendingRequests[index];
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (booking['name'] ?? 'User').toString().toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        (booking['email'] ?? 'unknown@mail.com')
                            .toString()
                            .toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6D87AE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PENDING',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildDataRow('MOVIE', booking['movie'] ?? 'Unknown'),
              _buildDataRow('REASON', booking['cancellationReason'] ?? 'Other'),
              _buildDataRow('DATE', booking['bookingDate'] ?? 'N/A'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleApproval(booking['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF109360,
                        ).withValues(alpha: 0.9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'APPROVE',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleRejection(booking['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF931010,
                        ).withValues(alpha: 0.9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'REJECT',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    if (_fullHistory.isEmpty) {
      return _buildEmptyState('No cancellation history');
    }

    return ListView.separated(
      itemCount: _fullHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = _fullHistory[index];
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (booking['name'] ?? 'User').toString().toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        (booking['email'] ?? 'unknown@mail.com')
                            .toString()
                            .toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF109360),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'APPROVED',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: Colors.black12),
              _buildDataRow('MOVIE', booking['movie'] ?? 'Unknown'),
              _buildDataRow(
                'ORIGINAL',
                'LKR ${booking['amount'] ?? '0.00'}',
                isBold: true,
              ),
              Builder(
                builder: (context) {
                  // Robust fallback calculation
                  double originalAmt =
                      double.tryParse(
                        booking['amount'].toString().replaceAll(
                          RegExp(r'[^0-9.]'),
                          '',
                        ),
                      ) ??
                      0.0;
                  String refund =
                      booking['refundAmount'] != null &&
                          booking['refundAmount'] != '0.00'
                      ? booking['refundAmount']
                      : (originalAmt * 0.5).toStringAsFixed(2);
                  String fee =
                      booking['cancellationFee'] != null &&
                          booking['cancellationFee'] != '0.00'
                      ? booking['cancellationFee']
                      : (originalAmt * 0.5).toStringAsFixed(2);

                  return _buildDataRow(
                    'REFUND',
                    'LKR $refund',
                    valueColor: const Color(0xFF109360),
                    isBold: true,
                    subText: 'FEE: LKR $fee',
                  );
                },
              ),
              _buildDataRow('DATE', booking['bookingDate'] ?? 'N/A'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
    String? subText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (subText != null)
                Text(
                  subText,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEF4444),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            message,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleApproval(String id) async {
    await BookingService.approveCancellation(id);
    _loadCancellations();
  }

  Future<void> _handleRejection(String id) async {
    await BookingService.rejectCancellation(id);
    _loadCancellations();
  }
}
