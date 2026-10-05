import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/app.dart';
import 'package:gwent_go/presentation/widgets/deck/deck_editor_parts.dart';
import 'package:gwent_go/presentation/widgets/gwent_card.dart';

void main() {
  testWidgets('each card is listed exactly once in the deck list', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GwentApp(
        home: Scaffold(
          body: DeckListPane(
            counts: const {'frost': 1, 'horn': 1, 'geralt': 1},
            onRemove: (_) {},
            onChangeLeader: () {},
            showChangeLeader: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    int occurrences(String id) => find
        .byWidgetPredicate((w) => w is GwentCard && w.definition.id == id)
        .evaluate()
        .length;

    // Weather cards have their own row group and must not also appear under
    // the special group.
    expect(occurrences('frost'), 1);
    expect(occurrences('horn'), 1);
    expect(occurrences('geralt'), 1);
  });
}
