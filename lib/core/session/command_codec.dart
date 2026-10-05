import '../models/card.dart';
import '../rules/game_command.dart';

/// Wire codec for [GameCommand]s: JSON-friendly maps carrying ids only.
abstract final class CommandCodec {
  static Map<String, Object?> encode(GameCommand command) => switch (command) {
    PlayCardCommand() => {
      'type': 'play',
      'player': command.player,
      'card': command.cardUid,
      if (command.targetRow != null) 'row': command.targetRow!.name,
      if (command.targetUid != null) 'target': command.targetUid,
    },
    ActivateLeaderCommand() => {
      'type': 'leader',
      'player': command.player,
      if (command.targetRow != null) 'row': command.targetRow!.name,
      if (command.targetUid != null) 'target': command.targetUid,
      if (command.discardUids.isNotEmpty) 'discard': command.discardUids,
      if (command.deckPickUid != null) 'deckPick': command.deckPickUid,
    },
    PassCommand() => {'type': 'pass', 'player': command.player},
    RedrawCommand() => {
      'type': 'redraw',
      'player': command.player,
      'card': command.cardUid,
    },
    FinishMulliganCommand() => {
      'type': 'finishMulligan',
      'player': command.player,
    },
    ChooseFirstPlayerCommand() => {
      'type': 'chooseFirstPlayer',
      'player': command.player,
      'firstPlayer': command.firstPlayer,
    },
  };

  /// Returns null when the payload is not a command this build understands.
  static GameCommand? decode(Map<String, Object?> json) {
    final player = json['player'];
    if (player is! int) return null;
    switch (json['type']) {
      case 'play':
        final card = json['card'];
        if (card is! int) return null;
        return PlayCardCommand(
          player: player,
          cardUid: card,
          targetRow: rowFromName(json['row'] as String?),
          targetUid: json['target'] as int?,
        );
      case 'leader':
        return ActivateLeaderCommand(
          player: player,
          targetRow: rowFromName(json['row'] as String?),
          targetUid: json['target'] as int?,
          discardUids: [
            for (final uid in (json['discard'] as List? ?? const []))
              if (uid is int) uid,
          ],
          deckPickUid: json['deckPick'] as int?,
        );
      case 'pass':
        return PassCommand(player);
      case 'redraw':
        final card = json['card'];
        if (card is! int) return null;
        return RedrawCommand(player: player, cardUid: card);
      case 'finishMulligan':
        return FinishMulliganCommand(player);
      case 'chooseFirstPlayer':
        final first = json['firstPlayer'];
        if (first is! int) return null;
        return ChooseFirstPlayerCommand(player: player, firstPlayer: first);
      default:
        return null;
    }
  }

  static CardRow? rowFromName(String? name) {
    if (name == null) return null;
    for (final row in CardRow.values) {
      if (row.name == name) return row;
    }
    return null;
  }

  /// Resolves a rejection name sent by the peer.
  static CommandRejection? rejectionFromName(String? name) {
    if (name == null) return null;
    for (final reason in CommandRejection.values) {
      if (reason.name == name) return reason;
    }
    return null;
  }
}
