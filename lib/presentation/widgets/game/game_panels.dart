import 'package:flutter/material.dart';

import '../../../core/data/faction_catalog.dart';
import '../../../core/models/card.dart';
import '../../../core/models/game_state.dart';
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
          Text(
            '$total',
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
              Text(
                '$total',
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

/// Selected-card preview with the play action.
class GamePreviewPanel extends StatelessWidget {
  const GamePreviewPanel({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final card = controller.selectedCard;
    return _SurfacePanel(
      child: card == null
          ? Align(
              alignment: Alignment.centerLeft,
              child: Text(
                strings.cardPreview.toUpperCase(),
                style: const TextStyle(
                  color: GwentColors.onSurfaceVariant,
                  fontSize: 12,
                  letterSpacing: 1.6,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GwentCard(definition: card.definition, width: 76),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _typeLine(context, card.definition),
                            style: const TextStyle(
                              color: GwentColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  strings.cardDescription(card.definition),
                  style: const TextStyle(
                    color: GwentColors.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: controller.engine.isHumanTurn
                          ? () => controller.playSelected()
                          : null,
                      icon: const Icon(Icons.double_arrow_rounded, size: 18),
                      label: Text(strings.playCard),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: controller.clearSelection,
                      child: Text(strings.cancel),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  String _typeLine(BuildContext context, CardDefinition card) {
    final strings = context.strings;
    if (card.isLeader) return strings.cardTypeLeader;
    if (card.isWeather) return strings.cardTypeWeather;
    if (card.isSpecial) return strings.cardTypeSpecial;
    final row = card.row == CardRow.agile ? CardRow.close : card.row;
    final hero = card.isHero ? ' · ${strings.tagHero}' : '';
    return '${strings.rowName(row)}$hero';
  }
}

/// Round-by-round score table shown in the desktop rail and the end dialog.
class GameScoreTable extends StatelessWidget {
  const GameScoreTable({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Table(
      columnWidths: const {0: FlexColumnWidth(1.4)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            for (final label in ['R1', 'R2', 'R3'])
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: GwentColors.onSurfaceVariant,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
          ],
        ),
        for (final player in state.players)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  player.isHuman ? strings.you : player.name,
                  style: const TextStyle(color: GwentColors.onSurfaceVariant),
                ),
              ),
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    _cell(player.index, i),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _color(player.index, i),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  String _cell(int player, int roundIndex) {
    if (roundIndex < state.roundHistory.length) {
      return '${state.roundHistory[roundIndex].scores[player]}';
    }
    if (roundIndex == state.roundNumber - 1 &&
        state.phase != GamePhase.gameOver) {
      return '${Scoring.playerTotal(state, player)}';
    }
    return '—';
  }

  Color _color(int player, int roundIndex) {
    if (roundIndex < state.roundHistory.length) {
      final winner = state.roundHistory[roundIndex].winner;
      if (winner == null) return GwentColors.onSurface;
      return winner == player ? GwentColors.goldBright : GwentColors.error;
    }
    if (roundIndex == state.roundNumber - 1) return GwentColors.onSurface;
    return GwentColors.outline;
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GwentColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GwentColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: child,
    );
  }
}
