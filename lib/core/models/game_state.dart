import 'card.dart';
import 'player.dart';

/// High level phase of a match.
enum GamePhase {
  /// Players are drawing and choosing their opening hands.
  mulligan,

  /// A round is in progress.
  playing,

  /// The match is over.
  gameOver,
}

/// Score of a single finished round.
class RoundResult {
  const RoundResult({
    required this.round,
    required this.scores,
    required this.winner,
  });

  final int round;

  /// Final score per player index.
  final List<int> scores;

  /// Winning player index, or `null` for a drawn round.
  final int? winner;
}

/// The authoritative state of a match.
///
/// This object contains no Flutter dependency and is safe to serialize in the
/// future; it is deliberately kept free of presentation concerns.
class GameState {
  GameState({
    required this.players,
    required this.roundNumber,
    required this.currentPlayer,
    required this.firstPlayer,
  }) : rows = List.generate(
         players.length * CardRow.combatRows.length,
         (i) => RowState(
           owner: i ~/ CardRow.combatRows.length,
           row: CardRow.combatRows[i % CardRow.combatRows.length],
         ),
       );

  final List<PlayerState> players;

  /// Battlefield rows indexed by `owner * 3 + rowIndex` where rowIndex follows
  /// [CardRow.combatRows] (close, ranged, siege).
  final List<RowState> rows;

  final List<CardInstance> weatherCards = [];
  final Set<String> activeWeather = {};

  final List<RoundResult> roundHistory = [];

  int roundNumber;
  int currentPlayer;
  int firstPlayer;

  GamePhase phase = GamePhase.mulligan;

  /// Monsters leader "Invader of the North": revives pick a random card.
  bool randomRespawn = false;

  /// Monsters leader "The Treacherous": spy cards count double.
  bool doubleSpyPower = false;

  /// Winner index once [phase] is [GamePhase.gameOver].
  int? matchWinner;

  bool get isOver => phase == GamePhase.gameOver;

  /// True once every seat has confirmed its opening hand.
  bool get allMulligansDone => players.every((p) => p.mulliganDone);

  PlayerState playerAt(int seat) => players[seat];

  int opponentOf(int player) => player == 0 ? 1 : 0;

  PlayerState opponent(PlayerState player) => players[opponentOf(player.index)];

  RowState rowState(int owner, CardRow row) =>
      rows[owner * CardRow.combatRows.length + CardRow.combatRows.indexOf(row)];

  List<RowState> rowsFor(int owner) => [
    for (final row in CardRow.combatRows) rowState(owner, row),
  ];
}
