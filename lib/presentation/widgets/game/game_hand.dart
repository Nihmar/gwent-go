import 'package:flutter/material.dart';

import '../../controllers/game_controller.dart';
import '../card_detail_dialog.dart';
import '../gwent_card.dart';

/// The player's hand, selectable and scrollable on both layouts.
class GameHand extends StatelessWidget {
  const GameHand({
    super.key,
    required this.controller,
    required this.cardWidth,
    this.scroll = false,
  });

  final GameController controller;
  final double cardWidth;

  /// When true the hand is laid out inside a vertical scroller (phone layout).
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final human = controller.human;
    final children = [
      for (final card in human.hand)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GwentCard(
            definition: card.definition,
            strength: card.baseStrength,
            width: cardWidth,
            showName: false,
            selected: identical(controller.selectedCard, card),
            dim:
                !controller.canPlayCard(card) &&
                controller.isLocalTurn,
            onTap: () => controller.selectCard(card),
            onLongPress: () => showCardDetail(
              context,
              card.definition,
              strength: card.baseStrength,
            ),
          ),
        ),
    ];
    if (scroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: children),
      );
    }
    return SizedBox(
      height: cardWidth * 6.35 / 4.45 + 4,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: children),
        ),
      ),
    );
  }
}
