import 'package:flutter/material.dart';

import '../../core/data/card_repository.dart';
import '../../core/models/card.dart';
import '../../core/models/player.dart';
import '../localization.dart';
import '../theme/gwent_colors.dart';
import '../widgets/board_background.dart';
import '../widgets/deck/deck_editor_parts.dart';

/// Collection browser and deck builder.
///
/// Editing is expressed as a mutable card-count map; the screen returns a new
/// [DeckDefinition] when saved. The heavy panes live in
/// `widgets/deck/deck_editor_parts.dart` to keep this file focused.
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
              Expanded(child: wide ? _wideBody(context) : _narrowBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final strings = context.strings;
    final wideHeader = MediaQuery.sizeOf(context).width >= 700;
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
          Expanded(
            child: DeckHeaderInfo(
              faction: _faction,
              title: strings.deckEditor,
              subtitle: '${strings.factionName(_faction)} · ${_leader.name}',
            ),
          ),
          if (wideHeader)
            TextButton(
              onPressed: _changeLeader,
              child: Text(strings.changeLeader),
            ),
          const SizedBox(width: 8),
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
          Expanded(child: _deckPane(context, false)),
          const SizedBox(width: 16),
          SizedBox(width: 300, child: _sidePane()),
        ],
      ),
    );
  }

  Widget _narrowBody(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Collection'),
              Tab(text: 'Deck'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _collectionPane(context),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _deckPane(context, true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _collectionPane(BuildContext context) {
    return DeckCollectionPane(
      collection: _collection,
      counts: _counts,
      search: _search,
      filter: _filter,
      onlyOwned: _onlyOwned,
      onSearchChanged: (value) => setState(() => _search = value),
      onFilterChanged: (row) => setState(() => _filter = row),
      onOnlyOwnedChanged: (value) => setState(() => _onlyOwned = value),
      onAdd: _add,
    );
  }

  Widget _deckPane(BuildContext context, bool showChangeLeader) {
    return DeckListPane(
      counts: _counts,
      onRemove: _remove,
      onChangeLeader: _changeLeader,
      showChangeLeader: showChangeLeader,
    );
  }

  Widget _sidePane() {
    return DeckSidePane(
      deck: _build(),
      leader: _leader,
      onChangeLeader: _changeLeader,
    );
  }
}
