import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';

/// Brand mark — tints for light theme so white-only assets stay visible.
class AppLogo extends StatelessWidget {
  final double fontSize;
  final Color? color;

  const AppLogo({super.key, this.fontSize = 28, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    final height = fontSize * 1.5;
    final fallbackColor = color ?? (isLight ? AppColors.text : Colors.white);

    Widget mark = Image.asset(
      'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Text(
          'MovieBuff',
          style: GoogleFonts.outfit(
            fontSize: fontSize * 0.95,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: fallbackColor,
          ),
        );
      },
    );

    if (isLight) {
      mark = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          AppColors.primaryBlueDeep,
          BlendMode.srcIn,
        ),
        child: mark,
      );
    }

    return mark;
  }
}
