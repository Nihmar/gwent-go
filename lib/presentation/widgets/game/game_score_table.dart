import 'package:flutter/material.dart';

import '../../../core/models/game_state.dart';
import '../../../core/rules/scoring.dart';
import '../../localization.dart';
import '../../theme/gwent_colors.dart';

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
