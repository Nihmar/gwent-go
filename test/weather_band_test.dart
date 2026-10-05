import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/app.dart';
import 'package:gwent_go/core/models/card.dart';
import 'package:gwent_go/core/rules/scoring.dart';
import 'package:gwent_go/presentation/widgets/board_widgets.dart';

import 'support/engine_harness.dart';

void main() {
  Future<void> pumpBand(WidgetTester tester, Set<String> weather) async {
    final engine = harness();
    engine.state.activeWeather
      ..clear()
      ..addAll(weather);
    Scoring.refresh(engine.state);
    await tester.pumpWidget(
      GwentApp(home: Scaffold(body: WeatherBand(state: engine.state))),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('weather band reports frost on the close row', (tester) async {
    await pumpBand(tester, {Ability.frost});
    expect(find.text('Close Combat at 1'), findsOneWidget);
  });

  testWidgets('weather band follows the active weather type', (tester) async {
    await pumpBand(tester, {Ability.fog});
    expect(find.text('Ranged Combat at 1'), findsOneWidget);
    expect(find.text('Close Combat at 1'), findsNothing);
  });

  testWidgets('weather band combines multiple weather effects', (tester) async {
    await pumpBand(tester, {Ability.fog, Ability.rain});
    expect(find.text('Ranged Combat at 1 · Siege Combat at 1'), findsOneWidget);
  });

  testWidgets('weather band reports clear weather when none is active', (
    tester,
  ) async {
    await pumpBand(tester, {});
    expect(find.text('Clear Weather not played'), findsOneWidget);
  });
}
