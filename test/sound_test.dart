import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/models/player.dart';
import 'package:gwent_go/core/rules/game_event.dart';
import 'package:gwent_go/presentation/audio/asset_sound_player.dart';
import 'package:gwent_go/presentation/audio/sound_cue_assets.dart';
import 'package:gwent_go/presentation/audio/sound_cues.dart';
import 'package:gwent_go/presentation/audio/sound_player.dart';
import 'package:gwent_go/presentation/audio/sound_service.dart';
import 'package:gwent_go/presentation/controllers/game_controller.dart';

import 'support/engine_harness.dart';

/// Records what would have been played.
class _RecordingPlayer implements SoundPlayer {
  final List<SoundCue> played = [];
  bool disposed = false;

  @override
  Future<void> play(SoundCue cue) async => played.add(cue);

  @override
  Future<void> dispose() async => disposed = true;
}

/// An asset bundle in which nothing can be found, like a build that ships
/// before the sound effects are recorded.
class _EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      throw Exception('missing asset $key');
}

final _card = CardInstance(
  uid: 1,
  definition: const CardDefinition(
    id: 'test_unit',
    name: 'Test Unit',
    faction: CardFaction.realms,
    row: CardRow.close,
    baseStrength: 10,
    artFilename: 'test_unit',
  ),
  owner: 0,
);

void main() {
  group('cues', () {
    test('actions carry a cue and bookkeeping events do not', () {
      expect(
        cueFor(CardPlayed(player: 0, card: _card, row: CardRow.close)),
        SoundCue.cardPlayed,
      );
      expect(cueFor(const PlayerPassed(1)), SoundCue.playerPassed);
      expect(cueFor(const MatchEnded(0)), SoundCue.matchEnded);
      expect(
        cueFor(const RoundEnded(round: 1, winner: 0, scores: [10, 5])),
        SoundCue.roundEnded,
      );
      expect(
        cueFor(const WeatherChanged({'weather_frost'})),
        SoundCue.weatherChanged,
      );
      expect(
        cueFor(const CardsDrawn(player: 0, count: 2)),
        SoundCue.cardsDrawn,
      );
      expect(
        cueFor(const LeaderActivated(player: 0, ability: 'leader_horn')),
        SoundCue.leaderActivated,
      );
      expect(
        cueFor(const AbilityTriggered(player: 0, ability: 'spy')),
        SoundCue.abilityTriggered,
      );

      // The start and the turn hand-off are silent on purpose.
      expect(cueFor(const MatchStarted()), isNull);
      expect(cueFor(const TurnChanged(1)), isNull);
    });

    test('a batch keeps the order and drops the silent events', () {
      expect(
        cuesFor([
          MatchStarted(),
          CardPlayed(player: 0, card: _card, row: CardRow.close),
          TurnChanged(1),
          PlayerPassed(1),
        ]),
        [SoundCue.cardPlayed, SoundCue.playerPassed],
      );
    });
  });

  group('assets', () {
    test('every cue maps to a unique bundled audio file', () {
      for (final cue in SoundCue.values) {
        final asset = assetForCue(cue);
        expect(asset, isNotNull, reason: 'no asset for ${cue.name}');
        expect(asset, startsWith('assets/audio/'), reason: cue.name);
        expect(asset, endsWith('.mp3'), reason: cue.name);
      }
      expect(
        soundCueAssets.values.toSet(),
        hasLength(SoundCue.values.length),
        reason: 'asset paths must be unique',
      );
    });

    test('a player without assets stays silent instead of failing', () async {
      final player = AssetSoundPlayer(bundle: _EmptyBundle());
      for (final cue in SoundCue.values) {
        await player.play(cue);
      }
      await player.dispose();
    });
  });

  group('service', () {
    test('plays the cues of the events it is given', () async {
      final player = _RecordingPlayer();
      final sounds = SoundService(player: player);

      await sounds.handle([
        CardPlayed(player: 0, card: _card, row: CardRow.close),
        PlayerPassed(1),
      ]);
      expect(player.played, [SoundCue.cardPlayed, SoundCue.playerPassed]);

      await sounds.dispose();
      expect(player.disposed, isTrue);
    });

    test('stays silent while the sound setting is off', () async {
      final player = _RecordingPlayer();
      var enabled = false;
      final sounds = SoundService(player: player, isEnabled: () => enabled);

      await sounds.handle([
        CardPlayed(player: 0, card: _card, row: CardRow.close),
      ]);
      expect(player.played, isEmpty);

      // The flag is read per batch, so unmuting takes effect at once.
      enabled = true;
      await sounds.handle([
        CardPlayed(player: 0, card: _card, row: CardRow.close),
      ]);
      expect(player.played, [SoundCue.cardPlayed]);

      enabled = false;
      await sounds.handle([PlayerPassed(1)]);
      expect(player.played, [SoundCue.cardPlayed]);
    });

    test('the silent player accepts cues without a backend', () async {
      const sounds = SilentSoundPlayer();
      await sounds.play(SoundCue.matchEnded);
      await sounds.dispose();
    });

    test('the controller forwards match events to the sound service', () {
      final decks = CardRepository.defaultDecks();
      final player = _RecordingPlayer();
      final sounds = SoundService(player: player);
      final controller = GameController(
        humanDeck: decks[0],
        opponentDeck: decks[1],
        difficulty: Difficulty.normal,
        seed: 3,
        sounds: sounds,
      );
      controller.start();
      controller.confirmMulligan();
      controller.state.currentPlayer = 0;
      controller.state.players[0].passed = false;
      controller.human.hand
        ..clear()
        ..add(makeCard('gryffin', owner: 0));
      final card = controller.human.hand.single;
      controller.selectCard(card);
      controller.playSelected();

      expect(player.played, contains(SoundCue.cardPlayed));
      controller.dispose();
      sounds.dispose();
    });
  });
}
