import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/app.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/presentation/widgets/gwent_card.dart';

void main() {
  Finder assetImage(String asset) => find.byWidgetPredicate(
    (widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == asset,
  );

  Future<Rect> pumpBadge(WidgetTester tester, String cardId) async {
    const width = 104.0;
    await tester.pumpWidget(
      GwentApp(
        home: Scaffold(
          body: GwentCard(
            definition: CardRepository.byId(cardId),
            width: width,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.getRect(find.byType(GwentCard));
  }

  testWidgets('leaders carry no power badge', (tester) async {
    await tester.pumpWidget(
      GwentApp(
        home: Scaffold(
          body: Column(
            children: [
              GwentCard(
                definition: CardRepository.byId('foltest_copper'),
                width: 80,
              ),
              GwentCard(definition: CardRepository.byId('gryffin'), width: 80),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Only the Griffin unit shows the standard white/gold power badge.
    expect(assetImage('assets/icons/power_normal.png'), findsOneWidget);
  });

  testWidgets('heroes use the hero power badge', (tester) async {
    await pumpBadge(tester, 'geralt');

    expect(assetImage('assets/icons/power_hero.png'), findsOneWidget);
    expect(assetImage('assets/icons/power_normal.png'), findsNothing);
  });

  testWidgets('the badge sits in the top-left corner of every card type', (
    tester,
  ) async {
    for (final id in ['gryffin', 'geralt', 'frost']) {
      final card = await pumpBadge(tester, id);
      final badge = tester.getRect(find.byKey(GwentCard.powerBadgeKey));

      expect(badge.width, closeTo(card.width * 0.24, 0.5), reason: id);
      expect(
        badge.left - card.left,
        closeTo(card.width * 0.045, 0.5),
        reason: id,
      );
      expect(badge.top - card.top, closeTo(card.width * 0.045, 0.5), reason: id);
      // Top-left, so the artwork centre stays clear.
      expect(badge.center.dx, lessThan(card.center.dx), reason: id);
      expect(badge.center.dy, lessThan(card.center.dy), reason: id);
    }
  });

  testWidgets('unit sprites are cropped to the disc', (tester) async {
    const width = 104.0;
    await pumpBadge(tester, 'gryffin');

    final badge = tester.getRect(find.byKey(GwentCard.powerBadgeKey));
    final sprite = tester.getRect(find.byKey(GwentCard.powerSpriteKey));

    // The 215px canvas is drawn so its 110px disc matches the badge box, then
    // shifted so the disc centre (69.2, 68.8) lands on the badge centre.
    expect(sprite.width, closeTo(width * 0.24 * 215 / 110, 0.5));
    expect(sprite.left + 69.2 / 215 * sprite.width, closeTo(badge.center.dx, 0.5));
    expect(sprite.top + 68.8 / 215 * sprite.height, closeTo(badge.center.dy, 0.5));

    // The strength sits in the middle of the disc.
    final number = tester.getRect(find.text('5'));
    expect(number.center.dx, closeTo(badge.center.dx, 0.5));
    expect(number.center.dy, closeTo(badge.center.dy, 0.5));
  });

  testWidgets('hero sprites keep their rays around the disc', (tester) async {
    const width = 104.0;
    await pumpBadge(tester, 'geralt');

    final badge = tester.getRect(find.byKey(GwentCard.powerBadgeKey));
    final sprite = tester.getRect(find.byKey(GwentCard.powerSpriteKey));

    // The 88px hero disc is scaled to the badge, so the surrounding rays make
    // the sprite well over twice the badge box.
    expect(sprite.width, closeTo(width * 0.24 * 215 / 88, 0.5));
    expect(sprite.width, greaterThan(badge.width * 2));
    expect(sprite.left, lessThan(badge.left));

    // The disc centre still lands on the badge, under the number.
    expect(sprite.left + 69.2 / 215 * sprite.width, closeTo(badge.center.dx, 0.5));
    expect(sprite.top + 68.8 / 215 * sprite.height, closeTo(badge.center.dy, 0.5));

    final number = tester.getRect(find.text('15'));
    expect(number.center.dx, closeTo(badge.center.dx, 0.5));
    expect(number.center.dy, closeTo(badge.center.dy, 0.5));
  });
}
