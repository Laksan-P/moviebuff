import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

/// Compact theme control — cycles System → Light → Dark.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.compact = false});

  final bool compact;

  static IconData iconFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.settings_brightness_rounded;
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
    }
  }

  static String labelFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System theme';
      case ThemeMode.light:
        return 'Light theme';
      case ThemeMode.dark:
        return 'Dark theme';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final mode = themeProv.mode;
    final icon = iconFor(mode);

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => themeProv.cycleMode(),
        customBorder: const CircleBorder(),
        child: Ink(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : scheme.surface.withValues(alpha: 0.95),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.22)
                  : scheme.outline.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                icon,
                key: ValueKey<ThemeMode>(mode),
                size: compact ? 22 : 24,
                color: scheme.primary,
              ),
            ),
          ),
        ),
      ),
    );

    return Tooltip(
      message: '${labelFor(mode)} · tap to change',
      child: Semantics(
        button: true,
        label: labelFor(mode),
        child: button,
      ),
    );
  }
}
