import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_mappers.dart';
import '../../services/booking_service.dart';
import '../../widgets/premium_screen_stack.dart';

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
    BookingService.refresh.addListener(_onBookingsRefreshSignal);
    _loadCancellations();
  }

  void _onBookingsRefreshSignal() {
    if (!mounted) return;
    _loadCancellations();
  }

  Future<void> _loadCancellations() async {
    try {
      final pending = await BookingService.getPendingCancellations();
      final allBookings = await BookingService.getBookings(admin: true);

      debugPrint(
        '🛠️ ADMIN CANCELLATIONS - pending API count=${pending.length}',
      );
      for (final booking in pending) {
        ApiMappers.logBookingStatus(booking);
        debugPrint(
          '  pending id=${booking['id']} api=${booking['_api_status']}',
        );
      }

      if (mounted) {
        setState(() {
          _pendingRequests = pending;
          _fullHistory = allBookings
              .where(ApiMappers.isCancelledBooking)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('🛠️ ADMIN CANCELLATIONS - load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    BookingService.refresh.removeListener(_onBookingsRefreshSignal);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: scheme.surface.withValues(alpha: 0.82),
        elevation: 0,
        foregroundColor: scheme.onSurface,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: scheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Back to Dashboard',
            style: GoogleFonts.outfit(
              color: scheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      body: PremiumScreenStack(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cancellation\nManagement',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Review and manage booking cancellations',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: scheme.primary,
                      indicatorWeight: 3,
                      labelColor: scheme.onSurface,
                      unselectedLabelColor: scheme.outline,
                      labelStyle: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      tabs: [
                        Tab(
                          text:
                              'Pending Requests (${_pendingRequests.length})',
                        ),
                        Tab(text: 'Full History (${_fullHistory.length})'),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPendingList(),
                          _buildHistoryList(),
                        ],
                      ),
                    ),
                  ],
                ),
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
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.25
                      : 0.06,
                ),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ApiMappers.bookingCustomerName(booking)
                              .toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          (ApiMappers.bookingCustomerEmail(booking).isEmpty
                                  ? 'unknown@mail.com'
                                  : ApiMappers.bookingCustomerEmail(booking))
                              .toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (booking['adminStatus'] ??
                              'Pending Cancellation Request')
                          .toString()
                          .toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFEA580C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(
                height: 32,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
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
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.25
                      : 0.06,
                ),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ApiMappers.bookingCustomerName(booking)
                              .toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          (ApiMappers.bookingCustomerEmail(booking).isEmpty
                                  ? 'unknown@mail.com'
                                  : ApiMappers.bookingCustomerEmail(booking))
                              .toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      'APPROVED',
                      style: GoogleFonts.outfit(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(
                height: 32,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
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
                    valueColor: AppColors.success,
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                    color: valueColor ?? scheme.onSurface,
                  ),
                ),
                if (subText != null)
                  Text(
                    subText,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: scheme.error,
                    ),
                  ),
              ],
            ),
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
