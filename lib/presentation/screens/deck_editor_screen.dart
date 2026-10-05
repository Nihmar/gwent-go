import 'package:flutter/material.dart';

import '../../core/data/card_repository.dart';
import '../../core/data/faction_catalog.dart';
import '../../core/models/card.dart';
import '../../core/models/player.dart';
import '../localization.dart';
import '../theme/gwent_colors.dart';
import '../widgets/board_background.dart';
import '../widgets/gwent_card.dart';

/// Collection browser and deck builder.
///
/// Editing is expressed as a mutable card-count map; the screen returns a new
/// [DeckDefinition] when saved. User-facing text is fully localized.
class DeckEditorScreen extends StatefulWidget {
  const DeckEditorScreen({
    super.key,
    required this.deck,
    required this.difficulty,
  });

  final DeckDefinition deck;
  final Difficulty difficulty;

  @override
  State<DeckEditorScreen> createState() => _DeckEditorScreenState();
}

class _DeckEditorScreenState extends State<DeckEditorScreen> {
  late final Map<String, int> _counts = Map.of(widget.deck.cardCounts);
  late CardDefinition _leader = widget.deck.leader;
  String _search = '';
  CardRow? _filter;
  bool _onlyOwned = false;

  CardFaction get _faction => widget.deck.faction;

  List<CardDefinition> get _collection {
    final query = _search.toLowerCase();
    return CardRepository.collectionFor(_faction).where((card) {
      if (_filter != null) {
        if (_filter == CardRow.leader) return false;
        if (card.row != _filter) return false;
      }
      if (_onlyOwned && (_counts[card.id] ?? 0) == 0) return false;
      if (query.isNotEmpty && !card.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  int get _total => _counts.values.fold(0, (a, b) => a + b);

  DeckDefinition _build() => DeckDefinition(
    id: widget.deck.id,
    name: '${widget.deck.name} (edited)',
    faction: _faction,
    leader: _leader,
    cardCounts: Map.of(_counts),
  );

  void _add(CardDefinition card) {
    final current = _counts[card.id] ?? 0;
    if (current >= card.maxCopies) return;
    setState(() => _counts[card.id] = current + 1);
  }

  void _remove(CardDefinition card) {
    final current = _counts[card.id] ?? 0;
    if (current <= 0) return;
    setState(() {
      if (current == 1) {
        _counts.remove(card.id);
      } else {
        _counts[card.id] = current - 1;
      }
    });
  }

  Future<void> _changeLeader() async {
    final leaders = CardRepository.leadersFor(_faction);
    final chosen = await showDialog<CardDefinition>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.strings.changeLeader),
        children: [
          for (final leader in leaders)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(leader),
              child: Text(leader.name),
            ),
        ],
      ),
    );
    if (chosen != null) setState(() => _leader = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      body: BoardBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: wide ? _wideBody(context) : _narrowBody(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final strings = context.strings;
    final info = factionInfo(_faction);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: GwentColors.surfaceLow,
        border: Border(
          bottom: BorderSide(
            color: GwentColors.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          Image.asset(info.shieldAsset, width: 22, height: 25),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.deckEditor,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${strings.factionName(_faction)} · ${_leader.name}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GwentColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width >= 700) ...[
            TextButton(
              onPressed: _changeLeader,
              child: Text(strings.changeLeader),
            ),
            const SizedBox(width: 8),
          ],
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_build()),
            child: Text(strings.saveDeck),
          ),
        ],
      ),
    );
  }

  Widget _wideBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 380, child: _collectionPane(context)),
          const SizedBox(width: 16),
          Expanded(child: _deckPane(context)),
          const SizedBox(width: 16),
          SizedBox(width: 300, child: _sidePane(context)),
        ],
      ),
    );
  }

  Widget _narrowBody(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [Tab(text: 'Collection'), Tab(text: 'Deck')]),
          Expanded(
            child: TabBarView(
              children: [
                Padding(padding: const EdgeInsets.all(12), child: _collectionPane(context)),
                Padding(padding: const EdgeInsets.all(12), child: _deckPane(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _collectionPane(BuildContext context) {
    final strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: strings.searchCollection,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: GwentColors.surfaceHigh,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(999)),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _filterChip(strings.filterAll, null),
            _filterChip(strings.filterUnits, CardRow.close),
            _filterChip(strings.filterSpecial, CardRow.special),
            _filterChip(strings.filterWeather, CardRow.weather),
            FilterChip(
              label: Text(strings.filterOwned),
              selected: _onlyOwned,
              onSelected: (value) => setState(() => _onlyOwned = value),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 108,
              childAspectRatio: 4.45 / 6.35,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _collection.length,
            itemBuilder: (context, index) {
              final card = _collection[index];
              final owned = _counts[card.id] ?? 0;
              final canAdd = owned < card.maxCopies;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  GwentCard(
                    definition: card,
                    width: 96,
                    onTap: canAdd ? () => _add(card) : null,
                  ),
                  if (owned > 0)
                    Positioned(
                      left: -4,
                      top: -4,
                      child: _Badge(text: '$owned/${card.maxCopies}'),
                    ),
                  if (canAdd)
                    const Positioned(
                      right: -4,
                      top: -4,
                      child: Icon(Icons.add_circle, color: GwentColors.goldBright, size: 18),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _deckPane(BuildContext context) {
    final strings = context.strings;
    final deck = _build();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(strings.deck.toUpperCase(), style: _titleStyle),
            const SizedBox(width: 10),
            Chip(label: Text('$_total / 40')),
            const SizedBox(width: 6),
            Chip(label: Text('${CardRepository.deckStrength(deck)} ${strings.strength}')),
            const Spacer(),
            if (MediaQuery.sizeOf(context).width < 700)
              TextButton(onPressed: _changeLeader, child: Text(strings.changeLeader)),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            children: [
              for (final row in CardRow.values)
                if (_cardsForRow(row).isNotEmpty)
                  _deckGroup(context, row, _cardsForRow(row)),
            ],
          ),
        ),
      ],
    );
  }

  List<CardDefinition> _cardsForRow(CardRow row) {
    final result = <CardDefinition>[];
    _counts.forEach((id, count) {
      final card = CardRepository.byId(id);
      if (card.row != row && !(row == CardRow.special && card.isWeather)) return;
      for (var i = 0; i < count; i++) {
        result.add(card);
      }
    });
    return result;
  }

  Widget _deckGroup(BuildContext context, CardRow row, List<CardDefinition> cards) {
    final strings = context.strings;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GwentColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GwentColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(strings.rowName(row), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Chip(
                label: Text('${cards.length}'),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 2,
            runSpacing: 6,
            children: [
              for (final card in cards)
                GwentCard(
                  definition: card,
                  width: 52,
                  showName: false,
                  onTap: () => _remove(card),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sidePane(BuildContext context) {
    final strings = context.strings;
    final deck = _build();
    final units = CardRepository.deckUnitCount(deck);
    final specials = CardRepository.deckSpecialCount(deck);
    final valid = units >= 22 && specials <= 10 && deck.totalCards <= 40;
    return ListView(
      children: [
        _surface(
          title: strings.deckStats,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statLine(strings.totalCards, '${deck.totalCards}'),
              _statLine(strings.unitCards, '$units / 22'),
              _statLine(strings.specialCards, '$specials / 10'),
              _statLine(strings.heroCards, '${CardRepository.deckHeroCount(deck)}'),
              _statLine(strings.totalStrength, '${CardRepository.deckStrength(deck)}'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: valid
                      ? GwentColors.gold.withValues(alpha: 0.12)
                      : GwentColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: valid
                        ? GwentColors.gold.withValues(alpha: 0.4)
                        : GwentColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  valid ? strings.deckValid : strings.deckInvalid,
                  style: TextStyle(
                    color: valid ? GwentColors.goldBright : GwentColors.error,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _surface(
          title: strings.leader,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GwentCard(definition: _leader, width: 60),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.cardDescription(_leader),
                      style: const TextStyle(
                        color: GwentColors.onSurfaceVariant,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    TextButton(
                      onPressed: _changeLeader,
                      child: Text(strings.changeLeader),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _surface(
          title: strings.factionAbility,
          child: Text(
            strings.factionAbilityDescription(_faction),
            style: const TextStyle(color: GwentColors.onSurfaceVariant, fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  Widget _surface({required String title, required Widget child}) => Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: GwentColors.surfaceLow,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: GwentColors.outlineVariant.withValues(alpha: 0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: _titleStyle),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );

  Widget _statLine(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: GwentColors.onSurfaceVariant, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _filterChip(String label, CardRow? row) => ChoiceChip(
    label: Text(label),
    selected: _filter == row,
    onSelected: (_) => setState(() => _filter = row),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: GwentColors.gold,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: GwentColors.onPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

const TextStyle _titleStyle = TextStyle(
  color: GwentColors.onSurfaceVariant,
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.4,
);
