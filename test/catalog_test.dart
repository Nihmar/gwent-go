import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/data/card_catalog.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/card.dart';

void main() {
  group('Card catalog', () {
    test('ids are unique', () {
      final ids = allCards.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every card has artwork on disk', () {
      for (final card in allCards) {
        final file = File('assets/cards/${card.artFilename}.jpg');
        expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');
      }
    });

    test('icons referenced by the UI exist', () {
      for (final asset in [
        'assets/icons/card_row_close.png',
        'assets/icons/card_row_ranged.png',
        'assets/icons/card_row_siege.png',
        'assets/icons/card_row_agile.png',
        'assets/icons/power_normal.png',
        'assets/icons/power_hero.png',
        'assets/icons/icon_gem_on.png',
        'assets/icons/icon_gem_off.png',
      ]) {
        expect(File(asset).existsSync(), isTrue, reason: 'missing $asset');
      }
    });
  });

  group('Default decks', () {
    test('only reference known cards', () {
      for (final deck in CardRepository.defaultDecks()) {
        deck.cardCounts.forEach((id, _) {
          expect(
            CardRepository.maybeById(id),
            isNotNull,
            reason: '${deck.id} references unknown card $id',
          );
        });
      }
    });

    test('leaders belong to the deck faction', () {
      for (final deck in CardRepository.defaultDecks()) {
        expect(deck.leader.faction, deck.faction, reason: deck.id);
        expect(deck.leader.isLeader, isTrue, reason: deck.id);
      }
    });

    test('every playable faction has a default deck', () {
      for (final faction in [
        CardFaction.realms,
        CardFaction.nilfgaard,
        CardFaction.monsters,
        CardFaction.scoiatael,
        CardFaction.skellige,
      ]) {
        expect(
          CardRepository.defaultDeckFor(faction),
          isNotNull,
          reason: faction.name,
        );
      }
    });

    test('cards are legal for the deck faction', () {
      for (final deck in CardRepository.defaultDecks()) {
        deck.cardCounts.forEach((id, _) {
          final card = CardRepository.byId(id);
          expect(
            CardRepository.isAllowedIn(card, deck.faction),
            isTrue,
            reason: '${card.name} in ${deck.id}',
          );
        });
      }
    });
  });
}
