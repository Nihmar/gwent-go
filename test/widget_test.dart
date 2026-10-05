import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/app.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/player.dart';
import 'package:gwent_go/presentation/screens/game_screen.dart';
import 'package:gwent_go/presentation/screens/home_screen.dart';

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
  });
}
