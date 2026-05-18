import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';

/// Brand mark from [assets/images/logo.png].
class AppLogo extends StatelessWidget {
  final double fontSize;
  final Color? color;
  final double? maxWidth;

  const AppLogo({
    super.key,
    this.fontSize = 28,
    this.color,
    this.maxWidth,
  });

  static const _assetPath = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = fontSize * 1.45;
    final widthCap = maxWidth ?? height * 3.2;
    final fallbackColor =
        color ?? (scheme.brightness == Brightness.light
            ? AppColors.text
            : Colors.white);

    final mark = Image.asset(
      _assetPath,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'MovieBuff',
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

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widthCap, maxHeight: height),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: mark,
      ),
    );
  }
}
