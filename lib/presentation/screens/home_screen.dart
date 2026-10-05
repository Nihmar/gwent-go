import 'package:flutter/material.dart';

import '../../core/data/card_repository.dart';
import '../../core/data/faction_catalog.dart';
import '../../core/models/card.dart';
import '../../core/models/player.dart';
import '../localization.dart';
import '../theme/gwent_colors.dart';
import '../widgets/board_background.dart';
import '../widgets/home/home_widgets.dart';
import '../widgets/selectors.dart';
import 'deck_editor_screen.dart';
import 'game_screen.dart';

/// Landing screen: pick a difficulty and faction, then start a match or edit
/// the deck. Layout adapts between a phone column and a desktop/tablet row.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Difficulty _difficulty = Difficulty.normal;
  CardFaction _faction = CardFaction.realms;
  late DeckDefinition _deck = CardRepository.defaultDeckFor(_faction)!;

  void _selectFaction(CardFaction faction) {
    setState(() {
      _faction = faction;
      _deck = CardRepository.defaultDeckFor(faction) ?? _deck;
    });
  }

  Future<void> _editDeck() async {
    final edited = await Navigator.of(context).push<DeckDefinition>(
      MaterialPageRoute(
        builder: (_) => DeckEditorScreen(deck: _deck, difficulty: _difficulty),
      ),
    );
    if (edited != null) {
      setState(() {
        _deck = edited;
        _faction = edited.faction;
      });
    }
  }

  void _startMatch() {
    final opponentFaction = playableFactions.firstWhere(
      (f) => f != _faction,
      orElse: () => CardFaction.monsters,
    );
    final opponentDeck = CardRepository.defaultDeckFor(opponentFaction)!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          humanDeck: _deck,
          opponentDeck: opponentDeck,
          difficulty: _difficulty,
        ),
      ),
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

  Widget _buildPhone(BuildContext context) {
    final strings = context.strings;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
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
                onPressed: () {},
                icon: const Icon(Icons.volume_up_outlined),
              ),
              IconButton(
                tooltip: strings.settings,
                onPressed: _showAbout,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeroBanner(
                  faction: _faction,
                  eyebrow: strings.appTagline,
                  height: 260,
                  compact: true,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    HomeChip(strings.threeDifficultyLevels),
                    HomeChip(strings.offline),
                    HomeChip(strings.classicRules),
                  ],
                ),
                const SizedBox(height: 18),
                HomeSectionLabel(strings.opponentDifficulty),
                const SizedBox(height: 8),
                DifficultySelector(
                  value: _difficulty,
                  onChanged: (value) => setState(() => _difficulty = value),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.difficultyDescription(_difficulty),
                  style: const TextStyle(
                    color: GwentColors.onSurfaceVariant,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 18),
                HomeSectionLabel(strings.faction),
                const SizedBox(height: 8),
                FactionSelector(value: _faction, onChanged: _selectFaction),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _startMatch,
                style: FilledButton.styleFrom(
                  backgroundColor: GwentColors.gold,
                  foregroundColor: GwentColors.onPrimary,
                  minimumSize: const Size.fromHeight(52),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(strings.play),
              ),
              const SizedBox(height: 10),
              TonalActionButton(
                onPressed: _editDeck,
                icon: Icons.grid_view_rounded,
                label: strings.deckCollection,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _showAbout,
                    child: Text(strings.settings),
                  ),
                  TextButton(onPressed: _showAbout, child: Text(strings.about)),
                ],
              ),
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
            } else if (index >= 2) {
              _showAbout();
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
                      onPressed: () {},
                      icon: const Icon(Icons.volume_up_outlined),
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
                          onDifficulty: (value) =>
                              setState(() => _difficulty = value),
                          onFaction: _selectFaction,
                          onStart: _startMatch,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 2,
                        child: DecksPanel(
                          deck: _deck,
                          onManage: _editDeck,
                          onSelect: (deck) => setState(() {
                            _deck = deck;
                            _faction = deck.faction;
                          }),
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
