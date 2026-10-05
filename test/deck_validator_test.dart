import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/models/collection.dart';
import 'package:gwent_go/core/rules/deck_validator.dart';

import 'support/engine_harness.dart';

void main() {
  group('DeckValidator', () {
    test('accepts every default deck', () {
      for (final deck in CardRepository.defaultDecks()) {
        final result = DeckValidator.validate(deck);
        expect(result.isValid, isTrue, reason: '${deck.id}: ${result.issues}');
      }
    });

    test('flags too few unit cards', () {
      final deck = testDeck(
        faction: CardFaction.realms,
        leaderId: 'foltest_gold',
        cards: const {'gryffin': 1},
      );
      expect(DeckValidator.validate(deck).has(DeckIssue.tooFewUnits), isTrue);
    });

    test('flags too many special cards', () {
      final deck = testDeck(
        faction: CardFaction.realms,
        leaderId: 'foltest_gold',
        cards: const {
          'geralt': 1,
          'decoy': 3,
          'horn': 3,
          'scorch': 3,
          'mardroeme': 3,
        },
      );
      expect(
        DeckValidator.validate(deck).has(DeckIssue.tooManySpecial),
        isTrue,
      );
    });

    test('flags too many cards in total', () {
      final deck = testDeck(
        faction: CardFaction.realms,
        leaderId: 'foltest_gold',
        cards: const {'gryffin': 45},
      );
      expect(DeckValidator.validate(deck).has(DeckIssue.tooManyCards), isTrue);
    });

    test('flags a leader that does not match the faction', () {
      final deck = testDeck(
        faction: CardFaction.realms,
        leaderId: 'eredin_silver',
        cards: const {'geralt': 1},
      );
      expect(
        DeckValidator.validate(deck).has(DeckIssue.leaderFactionMismatch),
        isTrue,
      );
    });

    test('flags cards from another faction', () {
      final deck = testDeck(
        faction: CardFaction.realms,
        leaderId: 'foltest_gold',
        cards: const {'fiend': 1},
      );
      expect(
        DeckValidator.validate(deck).has(DeckIssue.cardNotAllowed),
        isTrue,
      );
    });

    test('flags more copies than the card allows', () {
      final deck = testDeck(
        faction: CardFaction.realms,
        leaderId: 'foltest_gold',
        cards: const {'geralt': 2},
      );
      expect(DeckValidator.validate(deck).has(DeckIssue.tooManyCopies), isTrue);
    });

    test('ownership restricts the number of copies', () {
      final deck = testDeck(
        faction: CardFaction.realms,
        leaderId: 'foltest_gold',
        cards: const {'blue_stripes': 2},
      );
      expect(DeckValidator.validate(deck).isValid, isFalse);
      expect(
        DeckValidator.validate(
          deck,
          collection: const Collection({'blue_stripes': 2}),
        ).has(DeckIssue.tooManyCopies),
        isFalse,
      );
      expect(
        DeckValidator.validate(
          deck,
          collection: const Collection({'blue_stripes': 1}),
        ).has(DeckIssue.tooManyCopies),
        isTrue,
      );
    });

    test('Collection defaults to owning every card up to maxCopies', () {
      final card = CardRepository.byId('blue_stripes');
      expect(Collection.full.ownedCount(card), card.maxCopies);
      expect(const Collection({'blue_stripes': 1}).ownedCount(card), 1);
    });

    test('Collection JSON drops unknown ids and clamps counts', () {
      final collection = Collection.fromJson({
        'blue_stripes': 5,
        'unknown_card': 2,
        'geralt': -3,
      });
      expect(collection.ownedCount(CardRepository.byId('blue_stripes')), 3);
      expect(collection.ownedCount(CardRepository.byId('geralt')), 0);
    });
  });
}
