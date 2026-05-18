import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/connectivity_provider.dart';

/// Compact network state — subtle in online mode, clear when offline.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ConnectivityProvider, ({bool online, String label})>(
      selector: (_, c) => (online: c.isOnline, label: c.label),
      builder: (context, conn, _) {
        final online = conn.online;
        final scheme = Theme.of(context).colorScheme;

        final bg = online
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.error.withValues(alpha: 0.92);
        final fg = online ? scheme.onSurface : scheme.onError;

        return Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              border: Border(
                bottom: BorderSide(
                  color: online
                      ? scheme.outline.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  size: 18,
                  color: online ? scheme.primary : fg,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    conn.label,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: online ? scheme.onSurface : fg,
                    ),
                  ),
                ),
                if (!online)
                  Text(
                    'Cached',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: fg.withValues(alpha: 0.9),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
