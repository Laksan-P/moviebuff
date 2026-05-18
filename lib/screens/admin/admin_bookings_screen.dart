import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/booking_service.dart';
import '../../utils/text_safety.dart';
import '../../widgets/premium_screen_stack.dart';

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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Manage All Bookings'),
        backgroundColor: scheme.surface.withValues(alpha: 0.82),
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      body: PremiumScreenStack(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _bookings.isEmpty
            ? Center(
                child: Text(
                  'No bookings found',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                itemCount: _bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final booking = _bookings[index];
                  final shortId = TextSafety.safeBookingIdSuffix(booking['id']);
                  final status = booking['status'] ?? 'Confirmed';
                  final statusLower = status.toString().toLowerCase();
                  final bool isCancelled =
                      statusLower == 'cancelled' ||
                      statusLower == 'cancellation requested';

                  final chipBg = isCancelled
                      ? scheme.errorContainer
                      : scheme.tertiaryContainer;
                  final chipFg = isCancelled
                      ? scheme.onErrorContainer
                      : scheme.onTertiaryContainer;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: scheme.brightness == Brightness.dark
                                ? 0.28
                                : 0.05,
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
                              child: Text(
                                shortId,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: chipBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.toString().toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: chipFg,
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
                        _buildInfoRow('Movie', '${booking['movie'] ?? 'N/A'}'),
                        _buildInfoRow(
                          'Theatre',
                          '${booking['theatre'] ?? 'N/A'}',
                        ),
                        _buildInfoRow(
                          'Showtime',
                          '${booking['date']} @ ${booking['time']}',
                        ),
                        _buildInfoRow('Seats', '${booking['seats'] ?? 'N/A'}'),
                        Divider(height: 24, color: scheme.outlineVariant),
                        LayoutBuilder(
                          builder: (context, c) {
                            final stack = c.maxWidth < 320;
                            if (stack) {
                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'TOTAL PAID',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'LKR ${booking['amount'] ?? '0'}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'TOTAL PAID',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'LKR ${booking['amount'] ?? '0'}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: scheme.onSurface,
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
                  );
                },
              ),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
