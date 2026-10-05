import '../models/card.dart';

/// Events produced by the engine while resolving a match.
///
/// The UI consumes them to animate transitions and to render a log; the rules
/// never depend on them, which keeps the engine deterministic and testable.
sealed class GameEvent {
  const GameEvent();
}

class MatchStarted extends GameEvent {
  const MatchStarted();
}

class TurnChanged extends GameEvent {
  const TurnChanged(this.player);
  final int player;
}

class PlayerPassed extends GameEvent {
  const PlayerPassed(this.player);
  final int player;
}

class CardPlayed extends GameEvent {
  const CardPlayed({
    required this.player,
    required this.card,
    required this.row,
  });

  final int player;
  final CardInstance card;
  final CardRow? row;
}

class LeaderActivated extends GameEvent {
  const LeaderActivated({required this.player, required this.ability});
  final int player;
  final String ability;
}

class AbilityTriggered extends GameEvent {
  const AbilityTriggered({
    required this.player,
    required this.ability,
    this.cards = const [],
  });

  final int player;
  final String ability;
  final List<CardInstance> cards;
}

class CardsDrawn extends GameEvent {
  const CardsDrawn({required this.player, required this.count});
  final int player;
  final int count;
}

class WeatherChanged extends GameEvent {
  const WeatherChanged(this.activeWeather);
  final Set<String> activeWeather;
}

class RoundEnded extends GameEvent {
  const RoundEnded({required this.round, required this.winner, required this.scores});
  final int round;
  final int? winner;
  final List<int> scores;
}

class MatchEnded extends GameEvent {
  const MatchEnded(this.winner);
  final int? winner;
}
