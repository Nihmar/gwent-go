import 'package:flutter/material.dart';

import '../../core/data/card_repository.dart';
import '../../core/data/faction_catalog.dart';
import '../../core/models/card.dart';
import '../../core/models/player.dart';
import '../../core/persistence/key_value_store.dart';
import '../../core/persistence/profile_repository.dart';
import '../../core/rules/deck_validator.dart';
import '../audio/sound_service.dart';
import '../controllers/settings_controller.dart';
import '../localization.dart';
import '../theme/gwent_colors.dart';
import '../widgets/board_background.dart';
import '../widgets/home/home_widgets.dart';
import '../widgets/selectors.dart';
import 'deck_editor_screen.dart';
import 'game_screen.dart';
import 'lobby_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

/// Landing screen: pick a difficulty and faction, then start or continue a
/// match or edit the deck. Layout adapts between a phone column and a desktop
/// row.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.settings, this.sounds});

  /// Injected in production; tests get an in-memory controller by default.
  final SettingsController? settings;

  /// Sound effects for locally started matches; absent in tests and when the
  /// app did not supply a backend.
  final SoundService? sounds;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SettingsController _settings;
  late final bool _ownsSettings;

  @override
  void initState() {
    super.initState();
    _ownsSettings = widget.settings == null;
    _settings =
        widget.settings ??
        SettingsController(ProfileRepository(InMemoryKeyValueStore()));
    _settings.addListener(_onSettings);
    _settings.load();
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettings);
    if (_ownsSettings) _settings.dispose();
    super.dispose();
  }

  Difficulty get _difficulty => _settings.settings.difficulty;
  CardFaction get _faction => _settings.settings.faction;
  DeckDefinition get _deck => _settings.deckFor(_faction);

  Future<void> _editDeck() async {
    final result = await Navigator.of(context).push<DeckEditorResult>(
      MaterialPageRoute(
        builder: (_) => DeckEditorScreen(
          deck: _deck,
          difficulty: _difficulty,
          collection: _settings.collection,
        ),
      ),
    );
    if (result == null) return;
    await _settings.saveDeck(result.deck);
    if (result.startGame && mounted) _startMatch(deck: result.deck);
  }

  void _startMatch({DeckDefinition? deck, bool hotseat = false}) {
    final chosen = deck ?? _deck;
    final validation = DeckValidator.validate(
      chosen,
      collection: _settings.collection,
    );
    if (!validation.isValid) {
      _showInvalidDeck(validation);
      return;
    }
    final opponentFaction = playableFactions.firstWhere(
      (f) => f != chosen.faction,
      orElse: () => CardFaction.monsters,
    );
    final opponentDeck = CardRepository.defaultDeckFor(opponentFaction)!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          humanDeck: chosen,
          opponentDeck: opponentDeck,
          difficulty: _difficulty,
          hotseat: hotseat,
          sounds: widget.sounds,
          onFinished: _onMatchFinished,
          onPersist: (snapshot) => _settings.saveMatch(snapshot),
        ),
      ),
    );
  }

  void _showInvalidDeck(DeckValidationResult validation) {
    final strings = context.strings;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.invalidDeckTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final issue in validation.issues)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${strings.deckIssueMessage(issue)}'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _editDeck();
            },
            child: Text(strings.openDeckEditor),
          ),
        ],
      ),
    );
  }

  void _continueMatch() {
    final snapshot = _settings.savedMatch;
    if (snapshot == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          snapshot: snapshot,
          sounds: widget.sounds,
          onFinished: _onMatchFinished,
          onPersist: (value) => _settings.saveMatch(value),
        ),
      ),
    );
  }

  void _onMatchFinished(int? winner) {
    _settings.recordMatch(winner: winner, humanIndex: 0);
  }

  void _openLobby() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyScreen(settings: _settings),
      ),
    );
  }

  void _openStats() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => StatsScreen(settings: _settings)));
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SettingsScreen(settings: _settings)),
    );
  }

  void _showAbout() {
    final strings = context.strings;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.appTitle),
        content: Text(strings.appAbout),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: BoardBackground(
        child: SafeArea(
          child: wide ? _buildDesktop(context) : _buildPhone(context),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone / narrow layout
  // ---------------------------------------------------------------------------

  Widget _phoneTopBar(BuildContext context) {
    final strings = context.strings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
      child: Row(
        children: [
          Text(
            strings.appTitle,
            style: const TextStyle(
              color: GwentColors.goldBright,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 6,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: strings.sound,
            onPressed: _settings.toggleSound,
            icon: Icon(
              _settings.settings.soundEnabled
                  ? Icons.volume_up_outlined
                  : Icons.volume_off_outlined,
            ),
          ),
          IconButton(
            tooltip: strings.settings,
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: strings.about,
            onPressed: _showAbout,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildPhone(BuildContext context) {
    final strings = context.strings;
    return Column(
      children: [
        _phoneTopBar(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeroBanner(
                  faction: _faction,
                  eyebrow: strings.appTagline,
                  height: 176,
                  compact: true,
                ),
                const SizedBox(height: 16),
                HomeSectionLabel(strings.opponentDifficulty),
                const SizedBox(height: 8),
                DifficultySelector(
                  value: _difficulty,
                  onChanged: _settings.setDifficulty,
                ),
                const SizedBox(height: 6),
                Text(
                  strings.difficultyDescription(_difficulty),
                  style: const TextStyle(
                    color: GwentColors.onSurfaceVariant,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 16),
                HomeSectionLabel(strings.faction),
                const SizedBox(height: 8),
                FactionSelector(
                  value: _faction,
                  onChanged: _settings.setFaction,
                ),
                const SizedBox(height: 12),
                HomeDeckTile(deck: _deck, faction: _faction, onTap: _editDeck),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_settings.hasSavedMatch) ...[
                TonalActionButton(
                  onPressed: _continueMatch,
                  icon: Icons.play_circle_outline,
                  label: strings.continueMatch,
                ),
                const SizedBox(height: 8),
              ],
              FilledButton.icon(
                onPressed: _startMatch,
                style: FilledButton.styleFrom(
                  backgroundColor: GwentColors.gold,
                  foregroundColor: GwentColors.onPrimary,
                  minimumSize: const Size.fromHeight(50),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(strings.play),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TonalActionButton(
                      onPressed: () => _startMatch(hotseat: true),
                      icon: Icons.people_alt_outlined,
                      label: strings.localMatch,
                      height: 44,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TonalActionButton(
                      onPressed: _openLobby,
                      icon: Icons.wifi_tethering,
                      label: strings.lanMatch,
                      height: 44,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${strings.version} · ${strings.english}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GwentColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop / wide layout
  // ---------------------------------------------------------------------------

  Widget _buildDesktop(BuildContext context) {
    final strings = context.strings;
    return Row(
      children: [
        NavigationRail(
          selectedIndex: 0,
          labelType: NavigationRailLabelType.all,
          destinations: [
            NavigationRailDestination(
              icon: const Icon(Icons.play_arrow_outlined),
              selectedIcon: const Icon(Icons.play_arrow_rounded),
              label: Text(strings.play),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view_rounded),
              label: Text(strings.deckEditor),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.bar_chart_outlined),
              selectedIcon: const Icon(Icons.bar_chart_rounded),
              label: Text(strings.stats),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: Text(strings.settings),
            ),
          ],
          trailing: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              strings.version,
              style: const TextStyle(
                color: GwentColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
          onDestinationSelected: (index) {
            if (index == 1) {
              _editDeck();
            } else if (index == 2) {
              _openStats();
            } else if (index == 3) {
              _openSettings();
            }
          },
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      strings.play,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: GwentColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${strings.factionName(_faction)} · ${_deck.name}',
                      style: const TextStyle(
                        color: GwentColors.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                    const Spacer(),
                    HomeChip(strings.factionName(_faction)),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: strings.sound,
                      onPressed: _settings.toggleSound,
                      icon: Icon(
                        _settings.settings.soundEnabled
                            ? Icons.volume_up_outlined
                            : Icons.volume_off_outlined,
                      ),
                    ),
                    IconButton(
                      tooltip: strings.about,
                      onPressed: _showAbout,
                      icon: const Icon(Icons.info_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                HeroBanner(
                  faction: _faction,
                  eyebrow: strings.appTagline,
                  height: 300,
                  onContinue: _settings.hasSavedMatch ? _continueMatch : null,
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: NewMatchPanel(
                          difficulty: _difficulty,
                          faction: _faction,
                          deck: _deck,
                          onDifficulty: _settings.setDifficulty,
                          onFaction: _settings.setFaction,
                          onStart: _startMatch,
                          onStartLocal: () => _startMatch(hotseat: true),
                          onStartLan: _openLobby,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 2,
                        child: DecksPanel(
                          deck: _deck,
                          onManage: _editDeck,
                          onSelect: _settings.saveDeck,
                          stats: _settings.stats,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
