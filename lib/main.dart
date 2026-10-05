import 'package:flutter/material.dart';

import 'app.dart';
import 'core/persistence/profile_repository.dart';
import 'platform/shared_preferences_store.dart';
import 'presentation/audio/asset_sound_player.dart';
import 'presentation/audio/sound_service.dart';
import 'presentation/controllers/settings_controller.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await SharedPreferencesStore.create();
  final settings = SettingsController(ProfileRepository(store));
  // The service is app-scoped: it reads the live setting, so muting takes
  // effect at once, and it outlives individual matches.
  final sounds = SoundService(
    player: AssetSoundPlayer(),
    isEnabled: () => settings.settings.soundEnabled,
  );
  runApp(GwentApp(home: HomeScreen(settings: settings, sounds: sounds)));
}
