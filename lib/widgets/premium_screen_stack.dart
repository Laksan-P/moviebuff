import 'package:flutter/material.dart';

import 'cinematic_background.dart';

/// Full-screen [CinematicBackground] behind [child]. Use with a transparent
/// [Scaffold] for consistent polish (no blur on lists).
class PremiumScreenStack extends StatelessWidget {
  const PremiumScreenStack({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CinematicBackground(),
        child,
      ],
    );
  }
}
