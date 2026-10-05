import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/app.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/models/player.dart';
import 'package:gwent_go/core/rules/deck_validator.dart';
import 'package:gwent_go/l10n/generated/app_localizations.dart';
import 'package:gwent_go/presentation/localization.dart';
import 'package:gwent_go/presentation/screens/deck_editor_screen.dart';
import 'package:gwent_go/presentation/widgets/deck/deck_editor_parts.dart';
import 'package:gwent_go/presentation/widgets/deck/deck_summary_bar.dart';
import 'package:gwent_go/presentation/widgets/gwent_card.dart';

void main() {
  final defaultDeck = CardRepository.defaultDecks().first;

  /// Minimal deck: one copy of a card that still allows more copies.
  final smallDeck = DeckDefinition(
    id: 'test_small',
    name: 'Test small',
    faction: CardFaction.realms,
    leader: CardRepository.byId('foltest_gold'),
    cardCounts: const {'poor_infantry': 1},
  );

  Future<void> openEditor(WidgetTester tester, {DeckDefinition? deck}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GwentApp(
        home: DeckEditorScreen(
          deck: deck ?? defaultDeck,
          difficulty: Difficulty.normal,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations stringsOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(DeckEditorScreen)));

  String statValue(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  Finder tileFor(String id) => find.byWidgetPredicate(
    (widget) => widget is GwentCard && widget.definition.id == id,
  );

  testWidgets('phone editor keeps the deck summary and validation visible', (
    tester,
  ) async {
    await openEditor(tester);
    final strings = stringsOf(tester);

    expect(find.byType(DeckSummaryBar), findsOneWidget);
    expect(statValue(tester, DeckSummaryBar.cardsKey), '${defaultDeck.totalCards} / 40');
    final units = defaultDeck.cardCounts.entries
        .where((entry) => DeckValidator.isUnitCard(CardRepository.byId(entry.key)))
        .fold(0, (total, entry) => total + entry.value);
    expect(
      statValue(tester, DeckSummaryBar.unitsKey),
      '$units / ${DeckValidator.minUnits}',
    );
    expect(statValue(tester, DeckSummaryBar.specialKey), contains('/'));
    expect(statValue(tester, DeckSummaryBar.strengthKey), isNotEmpty);
    expect(find.text(strings.deckValid), findsOneWidget);
  });

  testWidgets('an invalid deck explains why Start game is disabled', (
    tester,
  ) async {
    await openEditor(tester, deck: smallDeck);
    final strings = stringsOf(tester);

    // One unit card is below the 22 minimum.
    expect(
      find.text(strings.deckIssueMessage(DeckIssue.tooFewUnits)),
      findsOneWidget,
    );
    final start = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, strings.startGame),
    );
    expect(start.onPressed, isNull);
  });

  testWidgets('tapping a collection card updates the live summary', (
    tester,
  ) async {
    await openEditor(tester, deck: smallDeck);
    expect(statValue(tester, DeckSummaryBar.cardsKey), '1 / 40');

    await tester.enterText(find.byType(TextField), 'Philippa');
    await tester.pumpAndSettle();
    await tester.tap(tileFor('philippa'));
    await tester.pumpAndSettle();

    expect(statValue(tester, DeckSummaryBar.cardsKey), '2 / 40');
  });

  testWidgets('the deck tab edits copies with steppers and updates the '
      'summary', (tester) async {
    await openEditor(tester, deck: smallDeck);
    final strings = stringsOf(tester);

    await tester.tap(find.textContaining('${strings.deck} ('));
    await tester.pumpAndSettle();
    expect(statValue(tester, DeckSummaryBar.cardsKey), '1 / 40');

    await tester.tap(find.byTooltip(strings.addCopy));
    await tester.pumpAndSettle();
    expect(statValue(tester, DeckSummaryBar.cardsKey), '2 / 40');

    await tester.tap(find.byTooltip(strings.removeCopy));
    await tester.pumpAndSettle();
    expect(statValue(tester, DeckSummaryBar.cardsKey), '1 / 40');
  });

  testWidgets('name, type, copies and ability sit under the card', (
    tester,
  ) async {
    await openEditor(tester, deck: smallDeck);
    await tester.enterText(find.byType(TextField), 'Poor');
    await tester.pumpAndSettle();

    Finder inCollection(String text) => find.descendant(
      of: find.byType(DeckCollectionPane),
      matching: find.text(text),
    );

    final card = tester.getRect(tileFor('poor_infantry'));
    final name = tester.getRect(inCollection('Poor Fucking Infantry'));

    // The card face is artwork only; the details live under it.
    expect(name.top, greaterThan(card.bottom));
    expect(inCollection('Close Combat'), findsOneWidget);
    expect(inCollection('1/4'), findsOneWidget);
    expect(inCollection('Tight Bond'), findsOneWidget);
  });

  testWidgets('long-press opens the ability sheet with copy actions', (
    tester,
  ) async {
    await openEditor(tester, deck: smallDeck);
    final strings = stringsOf(tester);

    await tester.enterText(find.byType(TextField), 'Philippa');
    await tester.pumpAndSettle();
    await tester.longPress(tileFor('philippa'));
    await tester.pumpAndSettle();

    final philippa = CardRepository.byId('philippa');
    expect(find.text(strings.abilityLabel.toUpperCase()), findsOneWidget);
    expect(find.text(strings.cardDescription(philippa)), findsOneWidget);

    await tester.tap(find.text(strings.addCopy));
    await tester.pumpAndSettle();
    expect(find.text(strings.inDeckCount(1, 1)), findsOneWidget);
    expect(find.text(strings.atCopyLimit), findsOneWidget);
  });

  testWidgets('saving an already edited deck does not grow its name', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    final deck = smallDeck.copyWith(name: 'Test small (edited)');
    DeckEditorResult? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await Navigator.of(context).push<DeckEditorResult>(
                  MaterialPageRoute(
                    builder: (_) => DeckEditorScreen(
                      deck: deck,
                      difficulty: Difficulty.normal,
                    ),
                  ),
                );
              },
              child: const Text('open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open editor'));
    await tester.pumpAndSettle();

    final strings = stringsOf(tester);
    await tester.tap(find.widgetWithText(FilledButton, strings.saveDeck));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.deck.name, 'Test small (edited)');
  });
}
