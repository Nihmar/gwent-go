import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'presentation/theme/app_theme.dart';

/// Root widget of the application.
class GwentApp extends StatelessWidget {
  const GwentApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
  }
}
