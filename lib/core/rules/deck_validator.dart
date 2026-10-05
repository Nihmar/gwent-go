import '../data/card_repository.dart';
import '../models/card.dart';
import '../models/collection.dart';
import '../models/player.dart';

/// Why a deck cannot be played. Language independent: the UI maps these to
/// localized messages.
enum DeckIssue {
  tooFewUnits,
  tooManySpecial,
  tooManyCards,
  leaderFactionMismatch,
  cardNotAllowed,
  tooManyCopies,
  unknownCard,
}

class DeckValidationResult {
  const DeckValidationResult(this.issues);

  final List<DeckIssue> issues;

  bool get isValid => issues.isEmpty;

  bool has(DeckIssue issue) => issues.contains(issue);
}

/// Deck building rules: at least [minUnits] unit cards, at most [maxSpecial]
/// special cards and at most [maxTotal] cards in total.
///
/// Heroes count as unit cards (they are units that merely ignore modifiers),
/// which matches the reference decks.
abstract final class DeckValidator {
  static const int minUnits = 22;
  static const int maxSpecial = 10;
  static const int maxTotal = 40;

  static bool isUnitCard(CardDefinition card) =>
      card.row.isUnitRow && !card.isLeader;

  static bool isSpecialCard(CardDefinition card) =>
      card.isSpecial || card.isWeather;

  static DeckValidationResult validate(
    DeckDefinition deck, {
    Collection collection = Collection.full,
  }) {
    final issues = <DeckIssue>{};
    if (deck.leader.faction != deck.faction) {
      issues.add(DeckIssue.leaderFactionMismatch);
    }

    var units = 0;
    var specials = 0;
    var total = 0;
    deck.cardCounts.forEach((id, count) {
      final card = CardRepository.maybeById(id);
      if (card == null || card.isLeader) {
        issues.add(DeckIssue.unknownCard);
        return;
      }
      if (!CardRepository.isAllowedIn(card, deck.faction)) {
        issues.add(DeckIssue.cardNotAllowed);
      }
      if (count > card.maxCopies || count > collection.ownedCount(card)) {
        issues.add(DeckIssue.tooManyCopies);
      }
      total += count;
      if (isUnitCard(card)) {
        units += count;
      } else if (isSpecialCard(card)) {
        specials += count;
      }
    });

    if (units < minUnits) issues.add(DeckIssue.tooFewUnits);
    if (specials > maxSpecial) issues.add(DeckIssue.tooManySpecial);
    if (total > maxTotal) issues.add(DeckIssue.tooManyCards);
    return DeckValidationResult(issues.toList());
  }
}
