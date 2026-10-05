import '../models/card.dart';
import '../models/player.dart';
import '../rules/game_engine.dart';

/// A single decision produced by the AI for its current turn.
sealed class AiAction {
  const AiAction();
}

class AiPlayCard extends AiAction {
  const AiPlayCard(this.card, {this.targetRow, this.target});

  final CardInstance card;
  final CardRow? targetRow;
  final CardInstance? target;
}

class AiActivateLeader extends AiAction {
  const AiActivateLeader({this.targetRow, this.target});

  final CardRow? targetRow;
  final CardInstance? target;
}

class AiPass extends AiAction {
  const AiPass();
}

/// Chooses the opponent's move. Implementations must never depend on Flutter.
abstract interface class AiPlayer {
  AiAction decide(GameEngine engine, PlayerState player);
}
