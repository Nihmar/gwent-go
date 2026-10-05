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
    await tester.pumpWidget(
      GwentApp(
        home: Scaffold(
          body: GwentCard(
            definition: CardRepository.byId('geralt'),
            width: 80,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(assetImage('assets/icons/power_hero.png'), findsOneWidget);
    expect(assetImage('assets/icons/power_normal.png'), findsNothing);
  });

  testWidgets('the unit sprite is cropped to the badge area', (tester) async {
    const width = 104.0;
    await tester.pumpWidget(
      GwentApp(
        home: Scaffold(
          body: GwentCard(definition: CardRepository.byId('gryffin'), width: width),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final badge = tester.getRect(find.byKey(GwentCard.powerBadgeKey));
    final sprite = tester.getRect(find.byKey(GwentCard.powerSpriteKey));
    final badgeSize = width * 0.44;

    // The 215px canvas is drawn so its 110px badge area matches the box, then
    // shifted by the sprite's (15, 14) content origin.
    expect(sprite.width, closeTo(badgeSize * 215 / 110, 0.5));
    expect(sprite.left, closeTo(badge.left - 15 * badgeSize / 110, 0.5));
    expect(sprite.top, closeTo(badge.top - 14 * badgeSize / 110, 0.5));

    // The strength sits in the middle of the badge box, i.e. of the circle.
    final number = tester.getRect(find.text('5'));
    expect(number.center.dx, closeTo(badge.center.dx, 0.5));
    expect(number.center.dy, closeTo(badge.center.dy, 0.5));
  });
}
