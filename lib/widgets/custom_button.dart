import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final double? width;
  final double? height;
  final Color? color;
  final Color? textColor;
  final Color? outlineColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    this.height,
    this.color,
    this.textColor,
    this.outlineColor,
  });

  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          color: isOutlined
              ? Colors.transparent
              : (color ?? scheme.primary),
          border: isOutlined || outlineColor != null
              ? Border.all(
                  color: outlineColor ?? scheme.primary,
                  width: 1.5,
                )
              : null,
          boxShadow: !isOutlined && outlineColor == null && !isLoading
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          child: isLoading
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: isOutlined
                        ? scheme.primary
                        : scheme.onPrimary,
                  ),
                )
              : Text(
                  text,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: textColor ??
                        (isOutlined
                            ? scheme.primary
                            : scheme.onPrimary),
                  ),
                ),
        ),
      ),
    );
  }
}
