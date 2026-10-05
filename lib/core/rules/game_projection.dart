import '../data/card_repository.dart';
import '../models/card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import 'scoring.dart';

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


/// Rebuilds a renderable [GameState] from a projection.
///
/// The result is not a full engine state: hidden zones stay empty and carry
/// their size on [PlayerState.handSize] and [PlayerState.deckSize]. Everything
/// the board renders — battlefields, row specials, weather, graveyards and the
/// derived strengths — matches the host's state, so the same widgets can render
/// a local match and a remote projection.
///
/// Throws [FormatException] when the payload references unknown cards or is
/// otherwise unusable.
GameState decodeProjection(Map<String, dynamic> json) {
  final cards = _decodeCards(json);
  final players = _decodePlayers(json, cards);
  final state = GameState(
    players: players,
    roundNumber: json['roundNumber'] as int? ?? 1,
    currentPlayer: json['currentPlayer'] as int? ?? 0,
    firstPlayer: json['firstPlayer'] as int? ?? 0,
  );

  for (final entry in (json['rows'] as List).cast<Map<String, dynamic>>()) {
    final owner = entry['owner'] as int;
    final row = _rowByName(entry['row'] as String? ?? '');
    final rowState = state.rowState(owner, row);
    _fill(entry['cards'], rowState.cards, cards);
    final specialUid = entry['special'];
    if (specialUid is int) rowState.special = cards[specialUid];
    rowState.weather = entry['weather'] as bool? ?? false;
    rowState.halfWeather = entry['halfWeather'] as bool? ?? false;
  }

  _fill(json['weather'], state.weatherCards, cards);
  state.activeWeather.addAll(
    (json['activeWeather'] as List? ?? const []).cast<String>(),
  );

  for (final entry
      in (json['history'] as List? ?? const []).cast<Map<String, dynamic>>()) {
    state.roundHistory.add(
      RoundResult(
        round: entry['round'] as int,
        scores: (entry['scores'] as List).cast<int>(),
        winner: entry['winner'] as int?,
      ),
    );
  }

  state.phase = GamePhase.values.byName(
    json['phase'] as String? ?? GamePhase.playing.name,
  );
  state.randomRespawn = json['randomRespawn'] as bool? ?? false;
  state.doubleSpyPower = json['doubleSpyPower'] as bool? ?? false;
  state.matchWinner = json['matchWinner'] as int?;

  // Strengths are derived: the client recomputes them from the visible cards
  // instead of trusting numbers from the host.
  Scoring.refresh(state);
  return state;
}

Map<int, CardInstance> _decodeCards(Map<String, dynamic> json) {
  final cards = <int, CardInstance>{};
  for (final entry in (json['cards'] as List).cast<Map<String, dynamic>>()) {
    final definition = CardRepository.maybeById(entry['id'] as String? ?? '');
    if (definition == null) {
      throw FormatException('Unknown card in projection: ${entry['id']}');
    }
    final uid = entry['uid'] as int;
    cards[uid] =
        CardInstance(
            uid: uid,
            definition: definition,
            owner: entry['owner'] as int? ?? 0,
          )
          ..noRemove = entry['noRemove'] as bool? ?? false
          ..removedTriggered = entry['removed'] as bool? ?? false
          ..temporary = entry['temporary'] as bool? ?? false;
  }
  return cards;
}

List<PlayerState> _decodePlayers(
  Map<String, dynamic> json,
  Map<int, CardInstance> cards,
) {
  final list = (json['players'] as List).cast<Map<String, dynamic>>();
  final players = <PlayerState>[];
  for (var i = 0; i < list.length; i++) {
    final entry = list[i];
    final faction = _factionByName(entry['faction'] as String?);
    final leader = CardRepository.maybeById(entry['leader'] as String? ?? '');
    if (faction == null || leader == null) {
      throw const FormatException('Unknown faction or leader in projection');
    }
    final player = PlayerState(
      index: i,
      name: entry['name'] as String? ?? 'Player ${i + 1}',
      faction: faction,
      leader: leader,
      isHuman: entry['human'] as bool? ?? false,
      difficulty: Difficulty.fromName(entry['difficulty'] as String? ?? ''),
      deckDefinition: DeckDefinition(
        id: 'projection_${faction.name}',
        name: 'Projection',
        faction: faction,
        leader: leader,
        cardCounts: const {},
      ),
    )
      ..leaderUsed = entry['leaderUsed'] as bool? ?? false
      ..passed = entry['passed'] as bool? ?? false
      ..roundsLost = entry['roundsLost'] as int? ?? 0
      ..isWinning = entry['winning'] as bool? ?? false
      ..redraws = entry['redraws'] as int? ?? 0
      ..mulliganDone = entry['mulliganDone'] as bool? ?? false;

    if (entry['hand'] == null) {
      player.hiddenHandCount = entry['handCount'] as int? ?? 0;
    } else {
      _fill(entry['hand'], player.hand, cards);
    }
    player.hiddenDeckCount = entry['deckCount'] as int? ?? 0;
    _fill(entry['graveyard'], player.graveyard, cards);
    players.add(player);
  }
  if (players.length != 2) {
    throw const FormatException('A projection needs exactly two players');
  }
  return players;
}

void _fill(
  Object? uids,
  List<CardInstance> target,
  Map<int, CardInstance> cards,
) {
  if (uids is! List) return;
  for (final uid in uids) {
    final card = cards[uid as int];
    if (card != null) target.add(card);
  }
}

CardFaction? _factionByName(String? name) {
  for (final faction in CardFaction.values) {
    if (faction.name == name) return faction;
  }
  return null;
}

CardRow _rowByName(String name) {
  for (final row in CardRow.values) {
    if (row.name == name) return row;
  }
  throw FormatException('Unknown row in projection: $name');
}
