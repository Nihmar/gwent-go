import '../models/card.dart';
import '../models/player.dart';
import 'card_catalog.dart';
import 'default_decks.dart';

/// Read-only access to the card catalog and the built-in decks.
///
/// The repository is intentionally free of any Flutter dependency.
abstract final class CardRepository {
  static final Map<String, CardDefinition> _byId = {
    for (final card in allCards) card.id: card,
  };

  static List<CardDefinition> get cards => allCards;

  static CardDefinition byId(String id) {
    final card = _byId[id];
    if (card == null) {
      throw ArgumentError.value(id, 'id', 'Unknown card id');
    }
    return card;
  }

  static CardDefinition? maybeById(String id) => _byId[id];

  static List<CardDefinition> leadersFor(CardFaction faction) =>
      allCards.where((c) => c.isLeader && c.faction == faction).toList();

  /// Whether [card] may be included in a deck of [faction].
  static bool isAllowedIn(CardDefinition card, CardFaction faction) {
    if (card.isLeader) return false;
    return card.faction == faction ||
        card.faction == CardFaction.neutral ||
        card.faction == CardFaction.special ||
        card.faction == CardFaction.weather;
  }

  /// Distinct collectible cards usable by [faction], strongest first.
  static List<CardDefinition> collectionFor(CardFaction faction) {
    final cards = allCards
        .where((c) => c.maxCopies > 0 && isAllowedIn(c, faction))
        .toList();
    cards.sort((a, b) {
      if (a.row != b.row) {
        final order = CardRow.values.indexOf(a.row) -
            CardRow.values.indexOf(b.row);
        return order;
      }
      if (a.baseStrength != b.baseStrength) {
        return b.baseStrength.compareTo(a.baseStrength);
      }
      return a.name.compareTo(b.name);
    });
    return cards;
  }

  static List<DeckDefinition> defaultDecks() =>
      defaultDeckBlueprints.map(toDeckDefinition).toList();

  static DeckDefinition toDeckDefinition(DeckBlueprint blueprint) =>
      DeckDefinition(
        id: blueprint.id,
        name: blueprint.name,
        faction: blueprint.faction,
        leader: byId(blueprint.leaderId),
        cardCounts: Map.unmodifiable(blueprint.cardCounts),
      );

  static DeckDefinition? defaultDeckFor(CardFaction faction) {
    for (final deck in defaultDecks()) {
      if (deck.faction == faction) return deck;
    }
    return null;
  }

  /// Total base strength of a deck, heroes included, as shown in the UI.
  static int deckStrength(DeckDefinition deck) {
    var total = 0;
    deck.cardCounts.forEach((id, count) {
      total += byId(id).baseStrength * count;
    });
    return total;
  }

  static int deckUnitCount(DeckDefinition deck) {
    var total = 0;
    deck.cardCounts.forEach((id, count) {
      if (byId(id).isUnit) total += count;
    });
    return total;
  }

  static int deckHeroCount(DeckDefinition deck) {
    var total = 0;
    deck.cardCounts.forEach((id, count) {
      if (byId(id).isHero) total += count;
    });
    return total;
  }

  static int deckSpecialCount(DeckDefinition deck) {
    var total = 0;
    deck.cardCounts.forEach((id, count) {
      final card = byId(id);
      if (card.isSpecial || card.isWeather) total += count;
    });
    return total;
  }
}
