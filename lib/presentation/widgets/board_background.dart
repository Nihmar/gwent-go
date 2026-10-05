import 'package:flutter/material.dart';

import '../theme/gwent_colors.dart';

/// The felt-like gradient behind every screen, built from widgets rather than
/// the reference board image (see AGENTS.md).
class BoardBackground extends StatelessWidget {
  const BoardBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: GwentColors.boardGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.92),
                radius: 1.2,
                colors: [Color(0x14FFD68C), Colors.transparent],
              ),
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}
