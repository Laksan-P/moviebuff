import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/connectivity_provider.dart';

/// Compact pill that shows current network state.
/// Online -> subtle green pill, Offline -> prominent red banner.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectivityProvider>();
    final online = conn.isOnline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: online
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
          : Theme.of(context).colorScheme.error,
      child: Row(
        children: [
          Icon(
            online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 16,
            color: online
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              conn.label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: online
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.white,
              ),
            ),
          ),
          if (!online)
            Text(
              'Showing cached data',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
  }
}
