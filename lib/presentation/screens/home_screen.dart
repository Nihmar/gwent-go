import 'package:flutter/material.dart';

import '../../core/data/card_repository.dart';
import '../../core/data/faction_catalog.dart';
import '../../core/models/card.dart';
import '../../core/models/player.dart';
import '../localization.dart';
import '../theme/gwent_colors.dart';
import '../widgets/board_background.dart';
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
                style: TextStyle(
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
                    _chip(strings.threeDifficultyLevels),
                    _chip(strings.offline),
                    _chip(strings.classicRules),
                  ],
                ),
                const SizedBox(height: 18),
                _sectionLabel(strings.opponentDifficulty),
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
                _sectionLabel(strings.faction),
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
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(strings.play),
              ),
              const SizedBox(height: 10),
              TonalButton(
                onPressed: _editDeck,
                icon: Icons.grid_view_rounded,
                label: strings.deckCollection,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(onPressed: _showAbout, child: Text(strings.settings)),
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
              style: const TextStyle(color: GwentColors.onSurfaceVariant, fontSize: 11),
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
                    _chip(strings.factionName(_faction)),
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
                        child: _NewMatchPanel(
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
                        child: _DecksPanel(
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

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: GwentColors.onSurfaceVariant,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.6,
    ),
  );

  Widget _chip(String text) => Chip(
    label: Text(text),
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

/// Gold-accented action button with a leading icon.
class TonalButton extends StatelessWidget {
  const TonalButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.height = 48,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

/// Large cinematic banner showing the selected faction artwork.
class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.faction,
    required this.eyebrow,
    this.height = 300,
    this.compact = false,
  });

  final CardFaction faction;
  final String eyebrow;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              factionInfo(faction).heroAsset,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.4),
              errorBuilder: (context, error, stack) => const ColoredBox(
                color: GwentColors.surfaceLow,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: compact ? Alignment.bottomCenter : Alignment.centerLeft,
                  end: compact ? Alignment.topCenter : Alignment.centerRight,
                  colors: const [Color(0xEB0A0704), Color(0x8A0A0704), Color(0x1A0A0704)],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 18 : 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: const TextStyle(
                      color: GwentColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.appTitle,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: compact ? 40 : 62,
                      height: 1,
                      letterSpacing: compact ? 4 : 6,
                      color: GwentColors.goldBright,
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, 4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: compact ? 360 : 520),
                    child: Text(
                      strings.appAbout,
                      style: const TextStyle(
                        color: GwentColors.onSurface,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewMatchPanel extends StatelessWidget {
  const _NewMatchPanel({
    required this.difficulty,
    required this.faction,
    required this.deck,
    required this.onDifficulty,
    required this.onFaction,
    required this.onStart,
  });

  final Difficulty difficulty;
  final CardFaction faction;
  final DeckDefinition deck;
  final ValueChanged<Difficulty> onDifficulty;
  final ValueChanged<CardFaction> onFaction;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.newMatch, style: _surfaceTitle),
          const SizedBox(height: 16),
          _fieldLabel(strings.opponentDifficulty),
          const SizedBox(height: 8),
          DifficultySelector(value: difficulty, onChanged: onDifficulty),
          const SizedBox(height: 6),
          Text(
            strings.difficultyDescription(difficulty),
            style: const TextStyle(color: GwentColors.onSurfaceVariant, fontSize: 12.5),
          ),
          const SizedBox(height: 18),
          _fieldLabel(strings.faction),
          const SizedBox(height: 8),
          FactionSelector(value: faction, onChanged: onFaction),
          const Spacer(),
          Row(
            children: [
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.double_arrow_rounded),
                label: Text(strings.startMatch),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${strings.factionName(faction)} · ${deck.leader.name}',
                  style: const TextStyle(
                    color: GwentColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecksPanel extends StatelessWidget {
  const _DecksPanel({
    required this.deck,
    required this.onManage,
    required this.onSelect,
  });

  final DeckDefinition deck;
  final VoidCallback onManage;
  final ValueChanged<DeckDefinition> onSelect;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final decks = CardRepository.defaultDecks();
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(strings.recentDecks, style: _surfaceTitle),
              const Spacer(),
              TextButton(onPressed: onManage, child: Text(strings.manageDecks)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: decks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = decks[index];
                return _DeckTile(
                  deck: item,
                  selected: item.id == deck.id,
                  onTap: () => onSelect(item),
                );
              },
            ),
          ),
          const Divider(height: 20),
          Row(
            children: [
              _Stat(label: strings.totalCards, value: '${deck.totalCards}'),
              _Stat(
                label: strings.totalStrength,
                value: '${CardRepository.deckStrength(deck)}',
              ),
              _Stat(label: strings.heroCards, value: '${CardRepository.deckHeroCount(deck)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeckTile extends StatelessWidget {
  const _DeckTile({required this.deck, required this.selected, required this.onTap});

  final DeckDefinition deck;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = factionInfo(deck.faction);
    final strings = context.strings;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? GwentColors.gold.withValues(alpha: 0.1) : null,
          border: Border.all(
            color: selected
                ? GwentColors.gold.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.asset(
                info.deckBackAsset,
                width: 36,
                height: 51,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${strings.factionName(deck.faction)} · '
                    '${deck.totalCards} ${strings.cards} · '
                    '${CardRepository.deckStrength(deck)} ${strings.strength}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GwentColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: GwentColors.goldBright),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: GwentColors.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: GwentColors.goldBright,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GwentColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GwentColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: child,
    );
  }
}

const TextStyle _surfaceTitle = TextStyle(
  color: GwentColors.onSurfaceVariant,
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.6,
);

Widget _fieldLabel(String text) => Text(
  text.toUpperCase(),
  style: const TextStyle(
    color: GwentColors.onSurfaceVariant,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  ),
);
