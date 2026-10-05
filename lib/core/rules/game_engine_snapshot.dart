part of 'game_engine.dart';

/// Serializes and restores a match so it can be paused and resumed later.
///
/// The encoding is plain JSON-friendly maps: card instances are stored once in
/// a flat registry and every zone references them by `uid`. Only card ids are
/// persisted, never the full definitions, so the snapshot survives catalog
/// updates for cards that still exist.
Map<String, dynamic> encodeMatch(
  GameState state, {
  required String opponentName,
  required int humanRedraws,
  int? randomSeed,
}) {
  final instances = <int, CardInstance>{};
  void collect(Iterable<CardInstance> cards) {
    for (final card in cards) {
      instances[card.uid] = card;
    }
  }

  for (final player in state.players) {
    collect(player.hand);
    collect(player.deck);
    collect(player.graveyard);
  }
  for (final row in state.rows) {
    collect(row.cards);
    final special = row.special;
    if (special != null) instances[special.uid] = special;
  }
  collect(state.weatherCards);

  return {
    'version': 1,
    'opponentName': opponentName,
    'humanRedraws': humanRedraws,
    'randomSeed': ?randomSeed,
    'roundNumber': state.roundNumber,
    'currentPlayer': state.currentPlayer,
    'firstPlayer': state.firstPlayer,
    'phase': state.phase.name,
    'randomRespawn': state.randomRespawn,
    'doubleSpyPower': state.doubleSpyPower,
    'matchWinner': state.matchWinner,
    'activeWeather': state.activeWeather.toList(),
    'cards': [
      for (final card in instances.values)
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
          'hand': [for (final c in player.hand) c.uid],
          'deck': [for (final c in player.deck) c.uid],
          'graveyard': [for (final c in player.graveyard) c.uid],
        },
    ],
    'rows': [
      for (final row in state.rows)
        {
          'owner': row.owner,
          'row': row.row.name,
          'cards': [for (final c in row.cards) c.uid],
          'special': row.special?.uid,
          'weather': row.weather,
          'halfWeather': row.halfWeather,
        },
    ],
    'weather': [for (final c in state.weatherCards) c.uid],
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

/// Returns true when [json] can be decoded into a playable match.
bool isValidMatchSnapshot(Map<String, dynamic> json) {
  try {
    decodeMatch(json);
    return true;
  } catch (_) {
    return false;
  }
}

/// Result of decoding a snapshot.
class DecodedMatch {
  const DecodedMatch(this.state, this.maxUid);

  final GameState state;
  final int maxUid;
}

/// Rebuilds a [GameState] from a snapshot. Throws [FormatException] when the
/// payload references unknown cards or is otherwise unusable.
DecodedMatch decodeMatch(Map<String, dynamic> json) {
  final players = _decodePlayers(json);
  final state = GameState(
    players: players,
    roundNumber: json['roundNumber'] as int? ?? 1,
    currentPlayer: json['currentPlayer'] as int? ?? 0,
    firstPlayer: json['firstPlayer'] as int? ?? 0,
  );

  final cardMap = _decodeCards(json);
  var maxUid = 0;
  for (final uid in cardMap.keys) {
    if (uid > maxUid) maxUid = uid;
  }

  for (var i = 0; i < players.length; i++) {
    final playerJson = (json['players'] as List)[i] as Map<String, dynamic>;
    _fill(playerJson['hand'], players[i].hand, cardMap);
    _fill(playerJson['deck'], players[i].deck, cardMap);
    _fill(playerJson['graveyard'], players[i].graveyard, cardMap);
    players[i]
      ..leaderUsed = playerJson['leaderUsed'] as bool? ?? false
      ..passed = playerJson['passed'] as bool? ?? false
      ..roundsLost = playerJson['roundsLost'] as int? ?? 0
      ..isWinning = playerJson['winning'] as bool? ?? false;
  }

  for (final entry in (json['rows'] as List).cast<Map<String, dynamic>>()) {
    final owner = entry['owner'] as int;
    final row = _rowByName(entry['row'] as String);
    final rowState = state.rowState(owner, row);
    _fill(entry['cards'], rowState.cards, cardMap);
    final specialUid = entry['special'];
    if (specialUid is int) rowState.special = cardMap[specialUid];
    rowState.weather = entry['weather'] as bool? ?? false;
    rowState.halfWeather = entry['halfWeather'] as bool? ?? false;
  }

  _fill(json['weather'], state.weatherCards, cardMap);
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

  Scoring.refresh(state);
  return DecodedMatch(state, maxUid);
}

List<PlayerState> _decodePlayers(Map<String, dynamic> json) {
  final list = (json['players'] as List).cast<Map<String, dynamic>>();
  final players = <PlayerState>[];
  for (var i = 0; i < list.length; i++) {
    final entry = list[i];
    final faction = _factionByName(entry['faction'] as String?);
    final leader = CardRepository.maybeById(entry['leader'] as String? ?? '');
    if (faction == null || leader == null) {
      throw const FormatException('Unknown faction or leader in snapshot');
    }
    players.add(
      PlayerState(
        index: i,
        name: entry['name'] as String? ?? 'Player $i',
        faction: faction,
        leader: leader,
        isHuman: entry['human'] as bool? ?? i == 0,
        difficulty: Difficulty.fromName(entry['difficulty'] as String? ?? ''),
        deckDefinition: DeckDefinition(
          id: 'restored_${faction.name}',
          name: 'Restored',
          faction: faction,
          leader: leader,
          cardCounts: const {},
        ),
      ),
    );
  }
  if (players.length != 2) {
    throw const FormatException('A match needs exactly two players');
  }
  return players;
}

Map<int, CardInstance> _decodeCards(Map<String, dynamic> json) {
  final cards = <int, CardInstance>{};
  for (final entry in (json['cards'] as List).cast<Map<String, dynamic>>()) {
    final definition = CardRepository.maybeById(entry['id'] as String? ?? '');
    if (definition == null) {
      throw FormatException('Unknown card in snapshot: ${entry['id']}');
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
  throw FormatException('Unknown row in snapshot: $name');
}
