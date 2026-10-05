import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/app.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/models/player.dart';
import 'package:gwent_go/presentation/controllers/game_controller.dart';
import 'package:gwent_go/presentation/screens/game_screen.dart';
import 'package:gwent_go/presentation/screens/home_screen.dart';
import 'package:gwent_go/presentation/widgets/game/game_hand.dart';
import 'package:gwent_go/presentation/widgets/game/game_overlays.dart';
import 'package:gwent_go/presentation/widgets/gwent_card.dart';

void setSurface(WidgetTester tester, double width, double height) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
}

void main() {
  group('Home screen', () {
    testWidgets('phone layout shows the play action', (tester) async {
      setSurface(tester, 412, 915);
      await tester.pumpWidget(const GwentApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('GWENT'), findsWidgets);
      expect(find.text('Play'), findsWidgets);
      expect(find.text('Normal'), findsOneWidget);
    });

    testWidgets('desktop layout shows the navigation rail', (tester) async {
      setSurface(tester, 1280, 800);
      await tester.pumpWidget(const GwentApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('New match'), findsOneWidget);
    });

    testWidgets('starting a match opens the mulligan board', (tester) async {
      setSurface(tester, 412, 915);
      await tester.pumpWidget(const GwentApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Play').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('redraw'), findsOneWidget);
      expect(find.text('Keep hand'), findsOneWidget);
    });

    testWidgets('deck collection opens the deck editor', (tester) async {
      setSurface(tester, 412, 915);
      await tester.pumpWidget(const GwentApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deck collection'));
      await tester.pumpAndSettle();

      expect(find.text('Deck editor'), findsOneWidget);
      expect(find.text('Save deck'), findsOneWidget);
    });
  });

  group('Game screen', () {
    final decks = CardRepository.defaultDecks();

    testWidgets('renders the mulligan on a phone footprint', (tester) async {
      setSurface(tester, 412, 915);
      await tester.pumpWidget(
        GwentApp(
          home: GameScreen(
            humanDeck: decks[0],
            opponentDeck: decks[1],
            difficulty: Difficulty.normal,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('redraw'), findsOneWidget);
    });

    testWidgets('renders the desktop rails and preview panel', (tester) async {
      setSurface(tester, 1280, 800);
      await tester.pumpWidget(
        GwentApp(
          home: GameScreen(
            humanDeck: decks[0],
            opponentDeck: decks[1],
            difficulty: Difficulty.hard,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CARD PREVIEW'), findsOneWidget);
    });

    testWidgets('phone flow lets the player select and play a card', (
      tester,
    ) async {
      setSurface(tester, 412, 915);
      await tester.pumpWidget(
        GwentApp(
          home: GameScreen(
            humanDeck: decks[0],
            opponentDeck: decks[1],
            difficulty: Difficulty.easy,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep hand'));
      await tester.pumpAndSettle();
      // Let a possible AI opening turn resolve; then it is the human's turn.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      final handCard = find
          .descendant(
            of: find.byType(GameHand),
            matching: find.byType(GwentCard),
          )
          .first;
      await tester.tap(handCard);
      await tester.pumpAndSettle();

      expect(find.text('Play card'), findsOneWidget);
      // The phone strip must also expose the leader control.
      expect(find.text('Ready'), findsWidgets);

      // Cancelling dismisses the sheet so another card can be selected.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Play card'), findsNothing);
    });

    testWidgets('leader multi-select asks for confirmation', (tester) async {
      setSurface(tester, 412, 915);
      final controller = GameController(
        humanDeck: DeckDefinition(
          id: 'test_leader',
          name: 'Test leader',
          faction: CardFaction.monsters,
          leader: CardRepository.byId('eredin_gold'),
          cardCounts: const {'gryffin': 12, 'nekker': 2},
        ),
        opponentDeck: CardRepository.defaultDecks()[1],
        difficulty: Difficulty.normal,
        seed: 3,
      );
      controller.start();
      controller.engine.finishMulligan();
      controller.state.currentPlayer = 0;
      controller.activateLeader();
      final choice = controller.pendingChoice!;

      await tester.pumpWidget(
        GwentApp(
          home: Scaffold(
            body: Stack(
              children: [ChoiceOverlay(controller: controller, choice: choice)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Discard 2 cards'), findsOneWidget);

      await tester.tap(find.byType(GwentCard).at(0));
      await tester.pump();
      await tester.tap(find.byType(GwentCard).at(1));
      await tester.pump();
      expect(find.text('Confirm (2/2)'), findsOneWidget);
      controller.dispose();
    });
  });
}
