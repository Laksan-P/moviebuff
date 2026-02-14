import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isOutlined
            ? Colors.transparent
            : (color ?? AppColors.primaryBlue),
        border: isOutlined || outlineColor != null
            ? Border.all(
                color: outlineColor ?? AppColors.primaryBlue,
                width: 1.5,
              )
            : null,
        boxShadow: !isOutlined && outlineColor == null && !isLoading
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      textColor ??
                      (isOutlined ? AppColors.primaryBlue : Colors.white),
                ),
              ),
      ),
    );
  }
}
