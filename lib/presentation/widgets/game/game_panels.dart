import 'package:flutter/material.dart';

import '../../../core/data/faction_catalog.dart';
import '../../../core/rules/scoring.dart';
import '../../controllers/game_controller.dart';
import '../../localization.dart';
import '../../theme/gwent_colors.dart';
import '../board_widgets.dart';
import '../gwent_card.dart';

/// Compact player summary used by the phone layout.
class GamePlayerStrip extends StatelessWidget {
  const GamePlayerStrip({
    super.key,
    required this.controller,
    required this.opponent,
  });

  final GameController controller;
  final bool opponent;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final player = opponent ? controller.opponent : controller.human;
    final total = Scoring.playerTotal(controller.state, player.index);
    final info = factionInfo(player.faction);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(
          top: opponent
              ? BorderSide.none
              : const BorderSide(color: Colors.white12),
          bottom: opponent
              ? const BorderSide(color: Colors.white12)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          AnimatedScore(
            value: total,
            style: const TextStyle(
              color: GwentColors.goldBright,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.points.toUpperCase(),
                style: const TextStyle(
                  color: GwentColors.onSurfaceVariant,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              RoundGems(roundsWon: player.roundsWon),
            ],
          ),
          if (!opponent) ...[
            const SizedBox(width: 10),
            _LeaderChip(controller: controller),
          ],
          const Spacer(),
          _HandCount(count: player.hand.length),
          const SizedBox(width: 6),
          Pile(
            count: player.deck.length,
            backAsset: info.deckBackAsset,
            width: 28,
          ),
          const SizedBox(width: 6),
          Pile(
            count: player.graveyard.length,
            backAsset: info.deckBackAsset,
            width: 28,
            graveyard: true,
            icon: Icons.delete_outline,
          ),
        ],
      ),
    );
  }
}

/// Compact leader control shown on the phone player strip.
class _LeaderChip extends StatelessWidget {
  const _LeaderChip({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final player = controller.human;
    final available = player.leaderAvailable && controller.engine.isHumanTurn;
    return Tooltip(
      message: strings.cardDescription(player.leader),
      child: GestureDetector(
        onTap: available ? controller.activateLeader : null,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GwentCard(
              definition: player.leader,
              width: 26,
              dim: !player.leaderAvailable,
            ),
            const SizedBox(height: 2),
            Text(
              available ? strings.leaderReady : strings.leaderUsed,
              style: TextStyle(
                color: available
                    ? GwentColors.goldBright
                    : GwentColors.onSurfaceVariant,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full player panel used by the desktop rails.
class GamePlayerPanel extends StatelessWidget {
  const GamePlayerPanel({
    super.key,
    required this.controller,
    required this.opponent,
  });

  final GameController controller;
  final bool opponent;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final player = opponent ? controller.opponent : controller.human;
    final total = Scoring.playerTotal(controller.state, player.index);
    final info = factionInfo(player.faction);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GwentColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GwentColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  info.heroAsset,
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opponent ? player.name : strings.you,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      strings.factionName(player.faction),
                      style: const TextStyle(
                        color: GwentColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (opponent)
                Chip(
                  label: Text(strings.difficultyName(player.difficulty)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              AnimatedScore(
                value: total,
                style: const TextStyle(
                  color: GwentColors.goldBright,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              RoundGems(roundsWon: player.roundsWon),
              const Spacer(),
              _HandCount(count: player.hand.length),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Pile(count: player.deck.length, backAsset: info.deckBackAsset),
              const SizedBox(width: 10),
              Pile(
                count: player.graveyard.length,
                backAsset: info.deckBackAsset,
                graveyard: true,
                icon: Icons.delete_outline,
              ),
              const Spacer(),
              if (!opponent)
                _LeaderButton(controller: controller)
              else
                GwentCard(definition: player.leader, width: 52),
            ],
          ),
        ],
      ),
    );
  }
}

class _HandCount extends StatelessWidget {
  const _HandCount({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GwentColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.style_outlined,
            size: 14,
            color: GwentColors.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text('$count', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _LeaderButton extends StatelessWidget {
  const _LeaderButton({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final player = controller.human;
    final available = player.leaderAvailable && controller.engine.isHumanTurn;
    return Column(
      children: [
        GwentCard(
          definition: player.leader,
          width: 52,
          dim: !player.leaderAvailable,
          onTap: available ? controller.activateLeader : null,
        ),
        const SizedBox(height: 3),
        Text(
          player.leaderAvailable ? strings.leaderReady : strings.leaderUsed,
          style: TextStyle(
            color: player.leaderAvailable
                ? GwentColors.goldBright
                : GwentColors.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
