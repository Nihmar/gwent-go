import '../models/card.dart';
import '../models/game_state.dart';

/// Serializes one seat's view of a match.
///
/// Public information — battlefields, row specials, weather, graveyards, round
/// history and every counter — is complete. Hidden information is reduced to
/// counts:
///
/// - the other seats' hands,
/// - every deck order, including the viewer's own, because no player is meant
///   to know what they will draw next.
///
/// The payload therefore never contains a hidden card id, which is what lets a
/// host hand it to a guest without leaking the match. It shares the card
/// registry format with the full snapshot so the two can be decoded by the same
/// reader once the client view lands.
Map<String, dynamic> encodeProjection(GameState state, {required int viewer}) {
  final visible = <int, CardInstance>{};
  void collect(Iterable<CardInstance> cards) {
    for (final card in cards) {
      visible[card.uid] = card;
    }
  }

  for (final player in state.players) {
    // Only the viewer's own hand is readable; graveyards are public.
    if (player.index == viewer) collect(player.hand);
    collect(player.graveyard);
  }
  for (final row in state.rows) {
    collect(row.cards);
    final special = row.special;
    if (special != null) visible[special.uid] = special;
  }
  collect(state.weatherCards);

  return {
    'version': 1,
    'viewer': viewer,
    'roundNumber': state.roundNumber,
    'currentPlayer': state.currentPlayer,
    'firstPlayer': state.firstPlayer,
    'phase': state.phase.name,
    'randomRespawn': state.randomRespawn,
    'doubleSpyPower': state.doubleSpyPower,
    'matchWinner': state.matchWinner,
    'activeWeather': state.activeWeather.toList(),
    'cards': [
      for (final card in visible.values)
        {
          'uid': card.uid,
          'id': card.id,
          'owner': card.owner,
          'noRemove': card.noRemove,
          'removed': card.removedTriggered,
          'temporary': card.temporary,
        },
    ],
    'players': [
      for (final player in state.players)
        {
          'name': player.name,
          'faction': player.faction.name,
          'leader': player.leader.id,
          'human': player.isHuman,
          'difficulty': player.difficulty.name,
          'leaderUsed': player.leaderUsed,
          'passed': player.passed,
          'roundsLost': player.roundsLost,
          'winning': player.isWinning,
          'redraws': player.redraws,
          'mulliganDone': player.mulliganDone,
          'hand': player.index == viewer
              ? [for (final card in player.hand) card.uid]
              : null,
          'handCount': player.hand.length,
          'deckCount': player.deck.length,
          'graveyard': [for (final card in player.graveyard) card.uid],
        },
    ],
    'rows': [
      for (final row in state.rows)
        {
          'owner': row.owner,
          'row': row.row.name,
          'cards': [for (final card in row.cards) card.uid],
          'special': row.special?.uid,
          'weather': row.weather,
          'halfWeather': row.halfWeather,
        },
    ],
    'weather': [for (final card in state.weatherCards) card.uid],
    'history': [
      for (final result in state.roundHistory)
        {
          'round': result.round,
          'scores': result.scores,
          'winner': result.winner,
        },
    ],
  };
}
