import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

/// Compact theme control — cycles System → Light → Dark.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.compact = false});

  final bool compact;

  static const double _size = 40;

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
    return Selector<ThemeProvider, ThemeMode>(
      selector: (_, p) => p.mode,
      builder: (context, mode, _) {
        final scheme = Theme.of(context).colorScheme;
        final isDark = scheme.brightness == Brightness.dark;
        final icon = iconFor(mode);
        final iconSize = compact ? 20.0 : 22.0;

        final button = SizedBox(
          width: _size,
          height: _size,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.read<ThemeProvider>().cycleMode(),
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
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      );
                      return FadeTransition(
                        opacity: curved,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.82, end: 1).animate(
                            curved,
                          ),
                          child: RotationTransition(
                            turns: Tween<double>(begin: 0.08, end: 0).animate(
                              curved,
                            ),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Icon(
                      icon,
                      key: ValueKey<ThemeMode>(mode),
                      size: iconSize,
                      color: scheme.primary,
                    ),
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
      },
    );
  }
}
