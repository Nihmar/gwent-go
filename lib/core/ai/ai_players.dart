import '../models/card.dart';
import '../models/player.dart';
import '../rules/game_engine.dart';
import 'ai.dart';
import 'ai_evaluator.dart';

/// Builds the opponent brain for a difficulty level.
AiPlayer createAi(Difficulty difficulty) => switch (difficulty) {
  Difficulty.easy => EasyAi(),
  Difficulty.normal => NormalAi(),
  Difficulty.hard => HardAi(),
};

/// Easy: greedy and impatient. Always plays the strongest card it holds and
/// never passes or uses its leader while it still has a card to play.
class EasyAi implements AiPlayer {
  @override
  AiAction decide(GameEngine engine, PlayerState player) {
    if (player.hand.isEmpty) return const AiPass();
    final cards = List<CardInstance>.of(player.hand)
      ..sort((a, b) => b.baseStrength.compareTo(a.baseStrength));
    final best = cards.first;
    return AiPlayCard(best);
  }
}

/// Normal: competently weighs every option and picks one at random, weighted by
/// value. Uses the same heuristics as the reference implementation.
class NormalAi implements AiPlayer {
  @override
  AiAction decide(GameEngine engine, PlayerState player) {
    final evaluator = AiEvaluator(engine, player.index);
    final candidates = evaluator.candidates();
    if (candidates.isEmpty) return const AiPass();
    final total = candidates.fold<double>(0, (a, c) => a + c.weight);
    if (total <= 0) {
      final playable = candidates.where((c) => c.action is! AiPass).toList();
      if (playable.isEmpty) return const AiPass();
      return playable.first.action;
    }
    var roll = engine.random.nextDouble() * total;
    for (final candidate in candidates) {
      roll -= candidate.weight;
      if (roll < 0) return candidate.action;
    }
    return candidates.last.action;
  }
}

/// Hard: deterministic greedy play with card-advantage aware passing.
///
/// Unlike Normal it never leaves a winning position to chance: it closes a
/// round when it is safe and holds onto finishers when it is already ahead.
class HardAi implements AiPlayer {
  @override
  AiAction decide(GameEngine engine, PlayerState player) {
    final evaluator = AiEvaluator(engine, player.index);
    final candidates = evaluator
        .candidates()
        .where((c) => c.action is! AiPass)
        .toList();
    final passWeight = _passWeight(evaluator);
    if (candidates.isEmpty) return const AiPass();
    AiCandidate best = candidates.first;
    for (final candidate in candidates) {
      if (candidate.weight > best.weight) best = candidate;
    }
    if (passWeight >= best.weight) return const AiPass();
    return best.action;
  }

  double _passWeight(AiEvaluator evaluator) {
    final player = evaluator.player;
    final opponent = evaluator.opponent;
    final difference = evaluator.playerTotal - evaluator.opponentTotal;

    // Winning the round is already secured once the opponent has passed.
    if (opponent.passed) {
      if (difference > 0) return 1000;
      return 0;
    }

    // Never pass a round that would cost the last gem.
    if (player.roundsWon == 1) return 0;

    // Comfortably ahead with no card deficit: bank the round and save cards.
    if (difference > 20 && player.hand.length <= opponent.hand.length) {
      return 40 + difference.toDouble();
    }

    // Behind and low on cards: pass to preserve resources for the next round.
    if (difference < -25 && opponent.hand.length > player.hand.length + 2) {
      return 60 - difference.toDouble();
    }

    return difference.abs().toDouble() * 0.5;
  }
}
