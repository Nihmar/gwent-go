import '../models/card.dart';

/// A serializable intent submitted to the rules engine.
///
/// Commands carry ids, not object references, so they can be sent over a wire
/// or recorded in a replay log. [GameEngine.apply] validates and resolves them.
sealed class GameCommand {
  const GameCommand();

  /// The seat that submitted the command.
  int get player;
}

/// Plays the card with [cardUid] from [player]'s hand.
///
/// [targetRow] is required for agile cards and row-special cards; [targetUid]
/// carries the chosen card for abilities that need one (Decoy, Medic, leaders
/// that revive or steal a card).
class PlayCardCommand extends GameCommand {
  const PlayCardCommand({
    required this.player,
    required this.cardUid,
    this.targetRow,
    this.targetUid,
  });

  @override
  final int player;
  final int cardUid;
  final CardRow? targetRow;
  final int? targetUid;
}

/// Activates [player]'s leader ability.
///
/// Leader abilities differ in what they need: a row (horns), a target card
/// (Relentless, Bringer of Death), up to two discards and a deck pick
/// (Destroyer of Worlds).
class ActivateLeaderCommand extends GameCommand {
  const ActivateLeaderCommand({
    required this.player,
    this.targetRow,
    this.targetUid,
    this.discardUids = const [],
    this.deckPickUid,
  });

  @override
  final int player;
  final CardRow? targetRow;
  final int? targetUid;
  final List<int> discardUids;
  final int? deckPickUid;
}

/// Passes the current round.
class PassCommand extends GameCommand {
  const PassCommand(this.player);

  @override
  final int player;
}

/// Swaps the card with [cardUid] during the opening mulligan.
class RedrawCommand extends GameCommand {
  const RedrawCommand({required this.player, required this.cardUid});

  @override
  final int player;
  final int cardUid;
}

/// Ends the opening mulligan for one seat.
class FinishMulliganCommand extends GameCommand {
  const FinishMulliganCommand(this.player);

  @override
  final int player;
}

/// Lets a lone Scoia'tael seat decide who takes the first turn.
class ChooseFirstPlayerCommand extends GameCommand {
  const ChooseFirstPlayerCommand({
    required this.player,
    required this.firstPlayer,
  });

  @override
  final int player;
  final int firstPlayer;
}

/// Why a [GameCommand] was rejected.
///
/// Language independent: the UI maps these to localized messages, the way
/// `DeckIssue` is handled.
enum CommandRejection {
  /// The match is not in a phase that accepts this command.
  wrongPhase,

  /// Another seat is acting.
  notYourTurn,

  /// The seat has already passed this round.
  playerPassed,

  /// No card with that id is on the table.
  unknownCard,

  /// The card is not in the seat's hand.
  cardNotInHand,

  /// The chosen row already holds the card's row-special slot.
  rowOccupied,

  /// The ability needs a target and none was provided or available.
  noTarget,

  /// The leader ability has been used or cannot be activated.
  leaderUnavailable,

  /// The seat has no redraws left.
  noRedrawsLeft,

  /// A step that was already completed, e.g. a finished mulligan.
  alreadyDone,

  /// The seat has no such decision to make.
  choiceNotAllowed,

  /// The chosen seat does not exist.
  invalidChoice,
}

/// Outcome of [GameEngine.apply].
sealed class CommandResult {
  const CommandResult();

  /// True when the command was applied.
  bool get accepted;
}

class CommandAccepted extends CommandResult {
  const CommandAccepted();

  @override
  bool get accepted => true;
}

class CommandRejected extends CommandResult {
  const CommandRejected(this.reason);

  final CommandRejection reason;

  @override
  bool get accepted => false;
}
