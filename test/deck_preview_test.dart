import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/app.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/models/player.dart';
import 'package:gwent_go/l10n/generated/app_localizations.dart';
import 'package:gwent_go/presentation/localization.dart';
import 'package:gwent_go/presentation/screens/deck_editor_screen.dart';
import 'package:gwent_go/presentation/widgets/deck/deck_list_pane.dart';

void main() {
  final smallDeck = DeckDefinition(
    id: 'test_small',
    name: 'Test small',
    faction: CardFaction.realms,
    leader: CardRepository.byId('foltest_gold'),
    cardCounts: const {'poor_infantry': 1},
  );

  testWidgets('long-press on a deck row opens the card preview', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GwentApp(
        home: DeckEditorScreen(
          deck: smallDeck,
          difficulty: Difficulty.normal,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final strings = AppLocalizations.of(
      tester.element(find.byType(DeckEditorScreen)),
    );
    await tester.tap(find.textContaining('${strings.deck} ('));
    await tester.pumpAndSettle();

    final rowName = find.descendant(
      of: find.byType(DeckListPane),
      matching: find.text('Poor Fucking Infantry'),
    );
    expect(rowName, findsOneWidget);

    await tester.longPress(rowName);
    await tester.pumpAndSettle();

    final card = CardRepository.byId('poor_infantry');
    expect(find.text(strings.abilityLabel.toUpperCase()), findsOneWidget);
    expect(find.text(strings.cardDescription(card)), findsOneWidget);
    expect(find.text(strings.inDeckCount(1, 4)), findsOneWidget);
  });
}
