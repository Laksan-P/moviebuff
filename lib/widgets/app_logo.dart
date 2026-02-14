import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;
  final Color color;

  const AppLogo({super.key, this.fontSize = 28, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: fontSize * 1.5, // Scale height relative to font size request
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to text if image is missing
        return SizedBox(width: fontSize * 4, height: fontSize * 1.5);
      },
    );
  }
}
