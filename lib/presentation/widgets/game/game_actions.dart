import 'package:flutter/material.dart';

import '../../controllers/game_controller.dart';
import '../../localization.dart';
import '../../theme/gwent_colors.dart';
import '../board_widgets.dart';

/// Turn indicator and the pass button.
///
/// [vertical] is used by the desktop side rail; the phone layout uses the
/// horizontal variant with an inline hint.
class GameActions extends StatelessWidget {
  const GameActions({
    super.key,
    required this.controller,
    this.showHint = false,
    this.vertical = false,
  });

  final GameController controller;
  final bool showHint;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final humanTurn = controller.engine.isHumanTurn && !controller.isMulligan;
    final turnChip = TurnChip(
      label: humanTurn ? strings.yourTurn : strings.opponentTurn,
      active: humanTurn,
    );
    final passButton = FilledButton.tonalIcon(
      onPressed: humanTurn ? controller.pass : null,
      icon: const Icon(Icons.flag_outlined, size: 18),
      label: Text(vertical ? strings.passRound : strings.pass),
      style: FilledButton.styleFrom(
        backgroundColor: GwentColors.surfaceHigh,
        foregroundColor: GwentColors.parchment,
      ),
    );

    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: turnChip),
          const SizedBox(height: 8),
          passButton,
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          turnChip,
          const Spacer(),
          if (showHint)
            Flexible(
              child: Text(
                strings.tapCardDetails,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GwentColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(width: 8),
          passButton,
        ],
      ),
    );
  }
}
