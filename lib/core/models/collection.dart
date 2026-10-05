import '../data/card_repository.dart';
import 'card.dart';

/// The cards a player owns, keyed by card id.
///
/// An empty map means the player owns the maximum number of copies of every
/// card, which is the default while there is no progression system. Explicit
/// entries override that, so a future collection screen can record ownership
/// without changing the deck editor or the validator.
class Collection {
  const Collection([this._owned = const {}]);

  final Map<String, int> _owned;

  static const Collection full = Collection();

  /// True when ownership is not restricted and every card's `maxCopies` apply.
  bool get isFull => _owned.isEmpty;

  int ownedCount(CardDefinition card) => _owned[card.id] ?? card.maxCopies;

  Map<String, int> toJson() => Map.of(_owned);

  static Collection fromJson(Map<String, dynamic> json) {
    final owned = <String, int>{};
    json.forEach((id, count) {
      if (count is! int) return;
      final card = CardRepository.maybeById(id);
      if (card == null) return;
      owned[id] = count.clamp(0, card.maxCopies);
    });
    return Collection(owned);
  }
}
