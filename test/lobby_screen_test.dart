import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/app.dart';
import 'package:gwent_go/core/persistence/key_value_store.dart';
import 'package:gwent_go/core/persistence/profile_repository.dart';
import 'package:gwent_go/presentation/controllers/lobby_controller.dart';
import 'package:gwent_go/presentation/controllers/settings_controller.dart';
import 'package:gwent_go/presentation/screens/lobby_screen.dart';

void main() {
  testWidgets('the lobby offers hosting and joining', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    final settings = SettingsController(
      ProfileRepository(InMemoryKeyValueStore()),
    );
    final lobby = LobbyController();
    addTearDown(() {
      settings.dispose();
      lobby.dispose();
    });

    await tester.pumpWidget(
      GwentApp(home: LobbyScreen(settings: settings, lobby: lobby)),
    );
    await tester.pumpAndSettle();

    expect(find.text('LAN match'), findsOneWidget);
    expect(find.text('Host match'), findsWidgets);
    expect(find.text('Join match'), findsWidgets);
    expect(find.text('No match found on this network'), findsOneWidget);
  });
}
