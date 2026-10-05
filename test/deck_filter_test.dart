import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/app.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/player.dart';
import 'package:gwent_go/presentation/screens/deck_editor_screen.dart';
import 'package:gwent_go/presentation/widgets/deck/deck_editor_parts.dart';

void main() {
  Finder inCollection(String text) => find.descendant(
    of: find.byType(DeckCollectionPane),
    // Restrict to Text widgets so the search field's EditableText, which also
    // renders the typed query, is not matched.
    matching: find.byWidgetPredicate((w) => w is Text && w.data == text),
  );

  Future<void> openEditor(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GwentApp(
        home: DeckEditorScreen(
          deck: CardRepository.defaultDecks().first,
          difficulty: Difficulty.normal,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectFilter(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('Units and Heroes filters separate heroes from units', (
    tester,
  ) async {
    await openEditor(tester);
    // Narrow the collection to a single known hero / unit.
    await tester.enterText(find.byType(TextField), 'Geralt');
    await tester.pumpAndSettle();
    expect(inCollection('Geralt of Rivia'), findsOneWidget);

    // A hero must not be listed under "Units".
    await selectFilter(tester, 'Units');
    expect(inCollection('Geralt of Rivia'), findsNothing);

    // ...but must be listed under "Heroes".
    await selectFilter(tester, 'Heroes');
    expect(inCollection('Geralt of Rivia'), findsOneWidget);
  });

  testWidgets('Units filter lists units from every row', (tester) async {
    await openEditor(tester);
    await tester.enterText(find.byType(TextField), 'Ballista');
    await tester.pumpAndSettle();
    expect(inCollection('Ballista'), findsOneWidget);

    // Ballista is a siege unit, so it must survive the "Units" filter.
    await selectFilter(tester, 'Units');
    expect(inCollection('Ballista'), findsOneWidget);

    // It is not a hero.
    await selectFilter(tester, 'Heroes');
    expect(inCollection('Ballista'), findsNothing);
  });
}
