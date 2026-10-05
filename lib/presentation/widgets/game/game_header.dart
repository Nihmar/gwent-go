import 'package:flutter/material.dart';

import '../../../core/data/faction_catalog.dart';
import '../../../core/models/game_state.dart';
import '../../controllers/game_controller.dart';
import '../../localization.dart';
import '../../theme/gwent_colors.dart';

/// Top bar of the match screen: opponent summary and round counter.
class GameHeader extends StatelessWidget {
  const GameHeader({super.key, required this.controller, this.compact = false});

  final GameController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final opponent = controller.opponent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: GwentColors.gold.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: strings.menu,
            icon: const Icon(Icons.menu),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          ClipOval(
            child: Image.asset(
              factionInfo(opponent.faction).heroAsset,
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponent.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  strings.opponentSummary(
                    strings.factionName(opponent.faction),
                    strings.difficultyName(opponent.difficulty),
                  ),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GwentColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!compact)
            Text(
              strings.appTitle,
              style: const TextStyle(
                fontFamily: 'serif',
                color: GwentColors.goldBright,
                letterSpacing: 4,
                fontSize: 18,
              ),
            ),
          const SizedBox(width: 8),
          _RoundChip(state: controller.state),
        ],
      ),
    );
  }
}

class _RoundChip extends StatelessWidget {
  const _RoundChip({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GwentColors.gold.withValues(alpha: 0.45)),
        color: GwentColors.gold.withValues(alpha: 0.1),
      ),
      alignment: Alignment.center,
      child: Text(
        strings.roundOf(state.roundNumber.clamp(1, 3), 3),
        style: const TextStyle(
          color: GwentColors.goldBright,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
