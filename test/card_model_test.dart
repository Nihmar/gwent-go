import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/core/models/card.dart';

void main() {
  group('CardDefinition.usesRowSpecialSlot', () {
    test('special cards with horn or mardroeme use the row slot', () {
      const horn = CardDefinition(
        id: 'test_horn',
        name: 'Test Horn',
        faction: CardFaction.special,
        row: CardRow.special,
        baseStrength: 0,
        artFilename: 'horn',
        abilities: [Ability.horn],
      );
      const mardroeme = CardDefinition(
        id: 'test_mardroeme',
        name: 'Test Mushroom',
        faction: CardFaction.special,
        row: CardRow.special,
        baseStrength: 0,
        artFilename: 'mardroeme',
        abilities: [Ability.mardroeme],
      );
      expect(horn.usesRowSpecialSlot, isTrue);
      expect(mardroeme.usesRowSpecialSlot, isTrue);
    });

    test('units with the same abilities occupy a normal slot', () {
      const dandelion = CardDefinition(
        id: 'test_dandelion',
        name: 'Dandelion',
        faction: CardFaction.neutral,
        row: CardRow.close,
        baseStrength: 2,
        artFilename: 'dandelion',
        abilities: [Ability.horn],
      );
      expect(dandelion.usesRowSpecialSlot, isFalse);
    });

    test('a renamed Horn card still uses the row slot', () {
      const renamed = CardDefinition(
        id: 'horn',
        name: "Commander's Horn (renamed)",
        faction: CardFaction.special,
        row: CardRow.special,
        baseStrength: 0,
        artFilename: 'horn',
        abilities: [Ability.horn],
      );
      expect(renamed.usesRowSpecialSlot, isTrue);
    });
  });
}
