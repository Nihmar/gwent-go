import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/models/collection.dart';
import 'package:gwent_go/core/models/player.dart';
import 'package:gwent_go/core/persistence/key_value_store.dart';
import 'package:gwent_go/core/persistence/profile_repository.dart';
import 'package:gwent_go/core/rules/game_engine.dart';
import 'package:gwent_go/presentation/controllers/settings_controller.dart';

import 'support/engine_harness.dart';

void main() {
  group('ProfileRepository', () {
    test('settings round-trip through the store', () async {
      final repository = ProfileRepository(InMemoryKeyValueStore());
      expect((await repository.loadSettings()).faction, CardFaction.realms);

      await repository.saveSettings(
        const AppSettings(
          difficulty: Difficulty.hard,
          faction: CardFaction.skellige,
          deckId: 'custom',
          soundEnabled: false,
        ),
      );

      final loaded = await repository.loadSettings();
      expect(loaded.difficulty, Difficulty.hard);
      expect(loaded.faction, CardFaction.skellige);
      expect(loaded.deckId, 'custom');
      expect(loaded.soundEnabled, isFalse);
    });

    test('decks round-trip and drop unknown cards', () async {
      final repository = ProfileRepository(InMemoryKeyValueStore());
      final deck = CardRepository.defaultDeckFor(CardFaction.realms)!;
      await repository.saveDeck(deck);

      final loaded = await repository.loadDeck(CardFaction.realms);
      expect(loaded, isNotNull);
      expect(loaded!.leader.id, deck.leader.id);
      expect(loaded.cardCounts, deck.cardCounts);

      final store = InMemoryKeyValueStore({
        'deck.realms': '{"faction":"realms","leader":"foltest_gold","cards":{"nope":3,"geralt":1}}',
      });
      final filtered = await ProfileRepository(store)
          .loadDeck(CardFaction.realms);
      expect(filtered!.cardCounts, {'geralt': 1});
    });

    test('statistics accumulate', () async {
      final repository = ProfileRepository(InMemoryKeyValueStore());
      await repository.recordMatch(winner: 0, humanIndex: 0);
      await repository.recordMatch(winner: 1, humanIndex: 0);
      final stats = await repository.recordMatch(winner: null, humanIndex: 0);
      expect(stats.matches, 3);
      expect(stats.wins, 1);
      expect(stats.losses, 1);
      expect(stats.draws, 1);
      expect(stats.winRate, closeTo(1 / 3, 0.001));
    });

    test('a saved match can be reloaded and decoded', () async {
      final repository = ProfileRepository(InMemoryKeyValueStore());
      final engine = harness();
      await repository.saveMatch(engine.toJson());

      final snapshot = await repository.loadMatch();
      expect(snapshot, isNotNull);
      expect(isValidMatchSnapshot(snapshot!), isTrue);
      final restored = GameEngine.fromJson(snapshot);
      expect(restored.state.roundNumber, engine.state.roundNumber);
    });

    test('collection defaults to full and round-trips restrictions', () async {
      final repository = ProfileRepository(InMemoryKeyValueStore());
      expect((await repository.loadCollection()).isFull, isTrue);

      await repository.saveCollection(Collection.fromJson({'blue_stripes': 2}));
      final loaded = await repository.loadCollection();
      expect(loaded.ownedCount(CardRepository.byId('blue_stripes')), 2);
    });
  });

  group('SettingsController', () {
    test('loads settings, decks and saved match on start', () async {
      final repository = ProfileRepository(InMemoryKeyValueStore());
      await repository.saveSettings(
        const AppSettings(
          difficulty: Difficulty.easy,
          faction: CardFaction.monsters,
          deckId: 'x',
          soundEnabled: true,
        ),
      );
      await repository.saveDeck(
        CardRepository.defaultDeckFor(CardFaction.realms)!,
      );
      await repository.saveMatch(harness().toJson());

      final controller = SettingsController(repository);
      await controller.load();
      expect(controller.loaded, isTrue);
      expect(controller.settings.difficulty, Difficulty.easy);
      expect(controller.deckFor(CardFaction.realms).id, 'realms_starter');
      expect(controller.hasSavedMatch, isTrue);
      controller.dispose();
    });

    test('recording a match clears the paused match', () async {
      final repository = ProfileRepository(InMemoryKeyValueStore());
      await repository.saveMatch(harness().toJson());
      final controller = SettingsController(repository);
      await controller.load();
      expect(controller.hasSavedMatch, isTrue);

      await controller.recordMatch(winner: 0, humanIndex: 0);
      expect(controller.hasSavedMatch, isFalse);
      expect(controller.stats.wins, 1);
      expect(await repository.loadMatch(), isNull);
      controller.dispose();
    });

    test('an invalid stored match is discarded on load', () async {
      final store = InMemoryKeyValueStore({'match.current': '{"cards":"bad"}'});
      final controller = SettingsController(ProfileRepository(store));
      await controller.load();
      expect(controller.hasSavedMatch, isFalse);
      expect(await store.getString('match.current'), isNull);
      controller.dispose();
    });
  });
}
