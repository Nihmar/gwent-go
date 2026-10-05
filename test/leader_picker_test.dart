import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/app.dart';
import 'package:gwent_go/core/data/card_repository.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/l10n/generated/app_localizations.dart';
import 'package:gwent_go/presentation/localization.dart';
import 'package:gwent_go/presentation/widgets/deck/leader_picker.dart';

void main() {
  final leaders = CardRepository.leadersFor(CardFaction.realms);

  AppLocalizations strings(WidgetTester tester) => AppLocalizations.of(
    tester.element(find.byType(LeaderPickerDialog)),
  );

  Future<void> openPicker(
    WidgetTester tester,
    void Function(CardDefinition?) onResult,
  ) async {
    await tester.pumpWidget(
      GwentApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  final result = await showLeaderPicker(
                    context,
                    faction: CardFaction.realms,
                    leaders: leaders,
                    current: leaders.first,
                  );
                  onResult(result);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the current leader with its ability description', (
    tester,
  ) async {
    await openPicker(tester, (_) {});

    expect(find.text(leaders.first.name), findsOneWidget);
    expect(find.text(strings(tester).cardDescription(leaders.first)),
        findsOneWidget);
    expect(find.text('LEADER ABILITY'), findsOneWidget);
  });

  testWidgets('browsing updates the effect and confirm returns the leader', (
    tester,
  ) async {
    CardDefinition? chosen;
    await openPicker(tester, (value) => chosen = value);

    await tester.tap(find.byTooltip(strings(tester).nextLeader));
    await tester.pumpAndSettle();

    expect(find.text(leaders[1].name), findsOneWidget);
    expect(find.text(strings(tester).cardDescription(leaders[1])),
        findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(chosen?.id, leaders[1].id);
  });

  testWidgets('dismissing returns null', (tester) async {
    CardDefinition? chosen;
    await openPicker(tester, (value) => chosen = value);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(chosen, isNull);
  });

  testWidgets('renders on a phone footprint', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    await openPicker(tester, (_) {});

    expect(find.text(leaders.first.name), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
  });
}
