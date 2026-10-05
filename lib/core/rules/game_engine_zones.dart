part of 'game_engine.dart';

/// Zone movement, board ordering and discard heuristics.
///
/// An extension keeps the helper surface out of the main resolver file while
/// still allowing direct access to the engine's private state.
extension _ZoneHelpers on _AbilityResolver {
  bool draw(PlayerState player, int count) {
    var drawn = false;
    for (var i = 0; i < count && player.deck.isNotEmpty; i++) {
      player.hand.add(player.deck.removeAt(0));
      drawn = true;
    }
    return drawn;
  }

  void clearWeatherCards() {
    for (final card in state.weatherCards) {
      state.players[card.owner].graveyard.add(card);
    }
    state.weatherCards.clear();
    state.activeWeather.clear();
  }

  RowState? _rowContaining(CardInstance card) {
    for (final row in state.rows) {
      if (row.cards.contains(card)) return row;
      if (row.special == card) return row;
    }
    return null;
  }

  _Zone detach(CardInstance card) {
    final owner = state.players[card.owner];
    if (owner.hand.remove(card)) return _Zone.hand;
    if (owner.deck.remove(card)) return _Zone.deck;
    if (owner.graveyard.remove(card)) return _Zone.grave;
    for (final row in state.rows) {
      if (row.cards.remove(card)) return _Zone.row;
      if (row.special == card) {
        row.special = null;
        return _Zone.special;
      }
    }
    if (state.weatherCards.remove(card)) return _Zone.weather;
    return _Zone.none;
  }

  void toGrave(CardInstance card) {
    final zone = detach(card);
    state.players[card.owner].graveyard.add(card);
    if (zone == _Zone.row || zone == _Zone.special) {
      _triggerRemoved(card);
    }
  }

  void toHand(CardInstance card) {
    final zone = detach(card);
    state.players[card.owner].hand.add(card);
    if (zone == _Zone.row || zone == _Zone.special) {
      _triggerRemoved(card);
    }
  }

  void _triggerRemoved(CardInstance card) {
    if (card.removedTriggered) return;
    String? summonId;
    if (card.hasAbility(Ability.avenger)) summonId = 'chort';
    if (card.hasAbility(Ability.avengerKambi)) summonId = 'hemdall';
    if (summonId == null) return;
    card.removedTriggered = true;
    final definition = CardRepository.maybeById(summonId);
    if (definition == null) return;
    final summon = CardInstance(
      uid: engine.nextUid(),
      definition: definition,
      owner: card.owner,
    );
    insertSorted(state.rowState(card.owner, CardRow.close), summon);
    engine._emit(
      AbilityTriggered(
        player: card.owner,
        ability: Ability.avenger,
        cards: [summon],
      ),
    );
  }

  void insertSorted(RowState row, CardInstance card) {
    var index = row.cards.length;
    for (var i = 0; i < row.cards.length; i++) {
      if (_compare(card, row.cards[i]) < 0) {
        index = i;
        break;
      }
    }
    row.cards.insert(index, card);
  }

  int _compare(CardInstance a, CardInstance b) {
    var diff = _factionRank(a) - _factionRank(b);
    if (diff != 0) return diff;
    diff = a.baseStrength - b.baseStrength;
    if (diff != 0) return diff;
    return a.name.compareTo(b.name);
  }

  int _factionRank(CardInstance card) {
    if (card.faction == CardFaction.special) return -2;
    if (card.faction == CardFaction.weather) return -1;
    return 0;
  }

  /// Hand discard priority, mirroring the reference AI heuristic.
  List<CardInstance> discardOrder(PlayerState player) {
    final cards = <CardInstance>[];
    final groups = <String, List<CardInstance>>{};
    final musters = player.hand
        .where((c) => c.hasAbility(Ability.muster))
        .toList();
    while (musters.isNotEmpty) {
      final current = musters.removeLast();
      final index = current.name.indexOf('-');
      final name = index == -1
          ? current.name
          : current.name.substring(0, index).trim();
      final group = groups.putIfAbsent(name, () => []);
      group.add(current);
      for (var j = musters.length - 1; j >= 0; j--) {
        if (musters[j].name.startsWith(name)) {
          group.add(musters.removeAt(j));
        }
      }
    }
    for (final group in groups.values) {
      group.sort(_compare);
      group.removeLast();
      cards.addAll(group);
    }
    final weathers = player.hand.where((c) => c.isWeather).toList();
    if (weathers.length > 1) {
      weathers.removeAt(random.nextInt(weathers.length));
      cards.addAll(weathers);
    }
    final normal = player.hand.where((c) => c.abilities.isEmpty).toList()
      ..sort(_compare);
    cards.addAll(normal);
    return cards;
  }
}
