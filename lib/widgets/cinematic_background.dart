import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Soft radial “glow” layers — no [BackdropFilter]; cheap to paint.
class CinematicBackground extends StatelessWidget {
  const CinematicBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.backgroundDark : AppColors.background;
    final blobA = isDark
        ? AppColors.glowBlue.withValues(alpha: 0.35)
        : AppColors.primaryBlue.withValues(alpha: 0.14);
    final blobB = isDark
        ? AppColors.glowNavy.withValues(alpha: 0.5)
        : AppColors.primaryBlueDeep.withValues(alpha: 0.08);

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(color: base)),
          Positioned(
            right: -80,
            top: -120,
            child: _glowBlob(280, blobA),
          ),
          Positioned(
            left: -100,
            top: MediaQuery.sizeOf(context).height * 0.25,
            child: _glowBlob(320, blobB),
          ),
          Positioned(
            right: -60,
            bottom: -80,
            child: _glowBlob(260, blobA.withValues(alpha: isDark ? 0.2 : 0.1)),
          ),
        ],
      ),
    );
  }

  Widget _glowBlob(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
