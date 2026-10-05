import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/models/game_state.dart';
import 'package:gwent_go/core/models/player.dart';
import 'package:gwent_go/core/rules/game_engine.dart';
import 'package:gwent_go/core/rules/game_random.dart';

// Kept high so cards injected by tests never collide with the engine's own
// uid sequence (which starts at 0).
int _uid = 1 << 20;

/// Builds a card instance directly, bypassing the deck builder.
CardInstance makeCard(String id, {int owner = 0}) => CardInstance(
  uid: _uid++,
  definition: CardRepository.byId(id),
  owner: owner,
);

DeckDefinition testDeck({
  required CardFaction faction,
  required String leaderId,
  Map<String, int> cards = const {'geralt': 1},
}) => DeckDefinition(
  id: 'test_${faction.name}',
  name: 'Test ${faction.name}',
  faction: faction,
  leader: CardRepository.byId(leaderId),
  cardCounts: cards,
);

/// A started match with both hands replaced by the caller.
GameEngine harness({
  CardFaction humanFaction = CardFaction.realms,
  CardFaction opponentFaction = CardFaction.monsters,
  String humanLeader = 'foltest_gold',
  String opponentLeader = 'eredin_silver',
  int seed = 7,
}) {
  final engine = GameEngine(
    firstDeck: testDeck(
      faction: humanFaction,
      leaderId: humanLeader,
      cards: const {
        'geralt': 1,
        'blue_stripes': 3,
        'stennis': 1,
        'yennefer': 1,
      },
    ),
    secondDeck: testDeck(
      faction: opponentFaction,
      leaderId: opponentLeader,
      cards: const {'gryffin': 1, 'nekker': 3, 'gargoyle': 1},
    ),
    difficulty: Difficulty.normal,
    random: GameRandom(seed),
  );
  engine.startMatch();
  engine.finishMulligan(0);
  engine.finishMulligan(1);
  return engine;
}

/// Replaces a player's hand and deck and clears any passed state.
void setHand(GameEngine engine, int player, List<String> ids) {
  final state = engine.state.players[player];
  state.hand
    ..clear()
    ..addAll(ids.map((id) => makeCard(id, owner: player)));
}

void setDeck(GameEngine engine, int player, List<String> ids) {
  final state = engine.state.players[player];
  state.deck
    ..clear()
    ..addAll(ids.map((id) => makeCard(id, owner: player)));
}

/// Forces the turn onto [player] and clears the passed flags.
void setTurn(GameEngine engine, int player) {
  engine.state.currentPlayer = player;
  engine.state.phase = GamePhase.playing;
  for (final p in engine.state.players) {
    p.passed = false;
  }
}
