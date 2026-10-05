import 'package:flutter/material.dart';

import '../controllers/settings_controller.dart';
import '../localization.dart';
import '../widgets/board_background.dart';

/// Application settings. Only an English locale ships today, so language is
/// shown as information rather than a selector.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: BoardBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: settings,
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: SwitchListTile(
                      title: Text(strings.sound),
                      value: settings.settings.soundEnabled,
                      onChanged: settings.setSoundEnabled,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      title: Text(strings.language),
                      subtitle: Text(strings.english),
                      trailing: const Icon(Icons.lock_outline, size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      title: Text(strings.resetStats),
                      trailing: const Icon(Icons.restart_alt),
                      onTap: settings.resetStats,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      title: Text(strings.about),
                      subtitle: Text(strings.appAbout),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
