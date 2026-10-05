import 'card.dart';

/// AI difficulty levels. Difficulty affects decision-making only: the rules
/// themselves never change between levels.
enum Difficulty {
  easy,
  normal,
  hard;

  static Difficulty fromName(String name) => Difficulty.values.firstWhere(
    (d) => d.name == name,
    orElse: () => Difficulty.normal,
  );
}

/// A named, validated deck: a faction, a leader and card counts.
class DeckDefinition {
  const DeckDefinition({
    required this.id,
    required this.name,
    required this.faction,
    required this.leader,
    required this.cardCounts,
  });

  final String id;
  final String name;
  final CardFaction faction;
  final CardDefinition leader;

  /// Card [CardDefinition.id] mapped to the number of copies in the deck.
  final Map<String, int> cardCounts;

  int get totalCards => cardCounts.values.fold(0, (a, b) => a + b);

  DeckDefinition copyWith({
    String? id,
    String? name,
    CardFaction? faction,
    CardDefinition? leader,
    Map<String, int>? cardCounts,
  }) => DeckDefinition(
    id: id ?? this.id,
    name: name ?? this.name,
    faction: faction ?? this.faction,
    leader: leader ?? this.leader,
    cardCounts: cardCounts ?? this.cardCounts,
  );
}

/// Mutable per-match state of one player.
class PlayerState {
  PlayerState({
    required this.index,
    required this.name,
    required this.faction,
    required this.leader,
    required this.isHuman,
    required this.difficulty,
    required this.deckDefinition,
  });

  final int index;
  String name;
  final CardFaction faction;
  CardDefinition leader;
  /// Whether a human controls this seat; set by the presentation/session.
  bool isHuman;
  final Difficulty difficulty;
  final DeckDefinition deckDefinition;

  final List<CardInstance> deck = [];
  final List<CardInstance> hand = [];
  final List<CardInstance> graveyard = [];

  bool leaderUsed = false;
  bool passed = false;
  bool isWinning = false;

  /// Redraws used during the opening mulligan.
  int redraws = 0;

  /// Set once the seat has confirmed its opening hand.
  bool mulliganDone = false;

  /// A player starts with two "gems"; each lost round removes one.
  int roundsLost = 0;

  int get roundsWon => 2 - roundsLost;
  bool get leaderAvailable =>
      !leaderUsed && leader.abilities.any(Ability.isActiveLeaderAbility);
  bool get isOutOfGems => roundsLost >= 2;

  /// True when the player still has a legal action other than passing.
  bool canPlay() => hand.isNotEmpty || leaderAvailable;

  @override
  String toString() => 'PlayerState($index, $name, $faction)';
}

/// Mutable state of a single battlefield row.
class RowState {
  RowState({required this.owner, required this.row});

  final int owner;
  final CardRow row;

  /// Unit cards currently in the row (heroes included).
  final List<CardInstance> cards = [];

  /// Card in the row special slot (Commander's Horn or Mardroeme).
  CardInstance? special;

  /// Whether a weather effect is currently reducing this row.
  bool weather = false;

  /// King Bran leader: units only lose half their strength in weather.
  bool halfWeather = false;

  bool get hasSpecial => special != null;
}
