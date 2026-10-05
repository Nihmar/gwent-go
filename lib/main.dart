import 'package:flutter/material.dart';

import 'app.dart';
import 'core/persistence/profile_repository.dart';
import 'platform/shared_preferences_store.dart';
import 'presentation/controllers/settings_controller.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await SharedPreferencesStore.create();
  final settings = SettingsController(ProfileRepository(store));
  runApp(GwentApp(home: HomeScreen(settings: settings)));
}
