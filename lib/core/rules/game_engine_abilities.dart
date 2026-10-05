part of 'game_engine.dart';

/// Where a card currently lives, used when moving it between zones.
enum _Zone { hand, deck, grave, row, special, weather, none }

/// Card placement, ability resolution and leader abilities.
///
/// Split from [GameEngine] to keep both files cohesive; sharing the library
/// lets the resolver manipulate the engine's private state directly.
class _AbilityResolver {
  _AbilityResolver(this.engine);

  final GameEngine engine;

  GameState get state => engine.state;
  GameRandom get random => engine.random;

  // ---------------------------------------------------------------------------
  // Placement
  // ---------------------------------------------------------------------------

  RowState? placeCard(
    PlayerState player,
    CardInstance card, {
    CardRow? targetRow,
  }) {
    if (card.isWeather) {
      _placeWeather(card);
      return null;
    }
    if (card.usesRowSpecialSlot) {
      final row = state.rowState(player.index, targetRow ?? CardRow.close);
      detach(card);
      row.special = card;
      return row;
    }
    final row = rowForCard(card, player.index, targetRow: targetRow);
    detach(card);
    insertSorted(row, card);
    return row;
  }

  RowState rowForCard(CardInstance card, int playerIndex, {CardRow? targetRow}) {
    if (card.hasAbility(Ability.spy)) {
      return state.rowState(state.opponentOf(playerIndex), _combatRowFor(card));
    }
    if (card.row == CardRow.agile) {
      return state.rowState(playerIndex, targetRow ?? CardRow.close);
    }
    return state.rowState(playerIndex, _combatRowFor(card));
  }

  CardRow _combatRowFor(CardInstance card) {
    if (card.row.isCombat) return card.row;
    return CardRow.close;
  }

  void _placeWeather(CardInstance card) {
    final player = state.players[card.owner];
    if (card.hasAbility(Ability.clear)) {
      clearWeatherCards();
      detach(card);
      player.graveyard.add(card);
      engine._emit(const WeatherChanged({}));
      return;
    }
    if (state.weatherCards.any((c) => c.name == card.name)) {
      detach(card);
      player.graveyard.add(card);
      return;
    }
    detach(card);
    state.weatherCards.add(card);
    var changed = false;
    for (final ability in card.abilities.where(Ability.isWeather)) {
      if (state.activeWeather.add(ability)) changed = true;
    }
    if (changed) {
      engine._emit(WeatherChanged(Set.unmodifiable(state.activeWeather)));
    }
  }

  // ---------------------------------------------------------------------------
  // Placed abilities
  // ---------------------------------------------------------------------------

  void resolvePlaced(
    PlayerState player,
    CardInstance card,
    RowState? row, {
    CardInstance? target,
  }) {
    if (row == null) return;
    for (final ability in card.abilities) {
      switch (ability) {
        case Ability.berserker:
          if (_rowHasMardroeme(row)) _transformBerserker(card, row);
        case Ability.mardroeme:
          _triggerMardroeme(row);
        case Ability.muster:
          _resolveMuster(player, card);
        case Ability.spy:
          draw(player, 2);
          engine._emit(CardsDrawn(player: player.index, count: 2));
          card.owner = state.opponentOf(player.index);
        case Ability.medic:
          _resolveMedic(player, target);
        case Ability.scorchClose:
          _resolveRowScorch(player, CardRow.close);
        case Ability.scorchRanged:
          _resolveRowScorch(player, CardRow.ranged);
        case Ability.scorchSiege:
          _resolveRowScorch(player, CardRow.siege);
        default:
          break;
      }
    }
  }

  bool _rowHasMardroeme(RowState row) {
    if (row.special?.hasAbility(Ability.mardroeme) ?? false) return true;
    return row.cards.any((c) => c.hasAbility(Ability.mardroeme));
  }

  void _triggerMardroeme(RowState row) {
    for (final card in List.of(row.cards)) {
      if (card.hasAbility(Ability.berserker)) {
        _transformBerserker(card, row);
      }
    }
  }

  void _transformBerserker(CardInstance card, RowState row) {
    final targetId = card.name.contains('Young') ? 'young_vildkaarl' : 'vildkaarl';
    final definition = CardRepository.maybeById(targetId);
    if (definition == null) return;
    row.cards.remove(card);
    final transformed = CardInstance(
      uid: engine.nextUid(),
      definition: definition,
      owner: card.owner,
    );
    insertSorted(row, transformed);
    engine._emit(
      AbilityTriggered(
        player: card.owner,
        ability: Ability.berserker,
        cards: [transformed],
      ),
    );
  }

  void _resolveMuster(PlayerState player, CardInstance card) {
    final index = card.name.indexOf('-');
    final prefix = index == -1 ? card.name : card.name.substring(0, index);
    final matches = <CardInstance>[
      ...player.hand.where((c) => c.name.startsWith(prefix)),
      ...player.deck.where((c) => c.name.startsWith(prefix)),
    ];
    for (final match in matches) {
      detach(match);
    }
    for (final match in matches) {
      final row = rowForCard(match, player.index);
      insertSorted(row, match);
      resolvePlaced(player, match, row);
    }
    if (matches.isNotEmpty) {
      engine._emit(
        AbilityTriggered(
          player: player.index,
          ability: Ability.muster,
          cards: matches,
        ),
      );
    }
  }

  void _resolveMedic(PlayerState player, CardInstance? requested) {
    final candidates = player.graveyard.where((c) => c.isUnit).toList();
    if (candidates.isEmpty) return;
    final revive = requested != null && candidates.contains(requested)
        ? requested
        : _autoMedicPick(candidates);
    player.graveyard.remove(revive);
    revive.owner = player.index;
    final row = rowForCard(revive, player.index);
    insertSorted(row, revive);
    resolvePlaced(player, revive, row);
    engine._emit(
      AbilityTriggered(
        player: player.index,
        ability: Ability.medic,
        cards: [revive],
      ),
    );
  }

  CardInstance _autoMedicPick(List<CardInstance> candidates) {
    final spies = candidates.where((c) => c.hasAbility(Ability.spy)).toList();
    if (spies.isNotEmpty) {
      spies.sort((a, b) => a.baseStrength.compareTo(b.baseStrength));
      return spies.first;
    }
    final medics = candidates.where((c) => c.hasAbility(Ability.medic)).toList();
    if (medics.isNotEmpty) {
      medics.sort((a, b) => b.baseStrength.compareTo(a.baseStrength));
      return medics.first;
    }
    final scorchers = candidates
        .where(
          (c) =>
              c.hasAbility(Ability.scorchClose) ||
              c.hasAbility(Ability.scorchRanged) ||
              c.hasAbility(Ability.scorchSiege),
        )
        .toList();
    if (scorchers.isNotEmpty) return random.pick(scorchers);
    candidates.sort((a, b) => b.baseStrength.compareTo(a.baseStrength));
    return candidates.first;
  }

  void _resolveRowScorch(PlayerState player, CardRow row) {
    final target = state.rowState(state.opponentOf(player.index), row);
    if (Scoring.rowTotal(state, target) < 10) return;
    _destroyCards(Scoring.strongestUnits(state, target));
  }

  void resolveGlobalScorch(PlayerState player) {
    final candidates = <CardInstance>[];
    var maxStrength = -1;
    for (final row in state.rows) {
      for (final unit in Scoring.strongestUnits(state, row)) {
        final strength = Scoring.cardStrength(state, row, unit);
        if (strength > maxStrength) {
          maxStrength = strength;
          candidates
            ..clear()
            ..add(unit);
        } else if (strength == maxStrength) {
          candidates.add(unit);
        }
      }
    }
    _destroyCards(candidates);
    if (candidates.isNotEmpty) {
      engine._emit(
        AbilityTriggered(
          player: player.index,
          ability: Ability.scorch,
          cards: candidates,
        ),
      );
    }
  }

  void _destroyCards(List<CardInstance> cards) {
    for (final card in cards) {
      if (card.isHero) continue;
      toGrave(card);
    }
  }

  // ---------------------------------------------------------------------------
  // Decoy
  // ---------------------------------------------------------------------------

  List<CardInstance> decoyTargets(PlayerState player) {
    final targets = <CardInstance>[];
    for (final row in state.rows) {
      targets.addAll(row.cards.where((c) => c.isUnit && c.owner == player.index));
    }
    return targets;
  }

  bool playDecoy(PlayerState player, CardInstance decoy, CardInstance? target) {
    final targets = decoyTargets(player);
    if (targets.isEmpty) return false;
    final chosen = target != null && targets.contains(target)
        ? target
        : targets.first;
    final row = _rowContaining(chosen);
    if (row == null) return false;
    toHand(chosen);
    detach(decoy);
    insertSorted(row, decoy);
    engine._emit(
      AbilityTriggered(
        player: player.index,
        ability: Ability.decoy,
        cards: [chosen],
      ),
    );
    Scoring.refresh(state);
    engine._endTurn();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Leader abilities
  // ---------------------------------------------------------------------------

  void resolveLeader(
    PlayerState player,
    String ability, {
    CardRow? targetRow,
    CardInstance? target,
  }) {
    switch (ability) {
      case 'foltest_king':
        _playWeatherFromDeck(player, Ability.fog);
      case 'foltest_lord':
        clearWeatherCards();
        engine._emit(const WeatherChanged({}));
      case 'foltest_siegemaster':
        _leaderHorn(player, CardRow.siege);
      case 'foltest_steelforged':
        _resolveRowScorch(player, CardRow.siege);
      case 'foltest_son':
        _resolveRowScorch(player, CardRow.ranged);
      case 'emhyr_imperial':
        _playWeatherFromDeck(player, Ability.rain);
      case 'emhyr_emperor':
        final hand = List.of(state.players[state.opponentOf(player.index)].hand);
        random.shuffle(hand);
        engine._emit(
          AbilityTriggered(
            player: player.index,
            ability: ability,
            cards: hand.take(3).toList(),
          ),
        );
      case 'emhyr_relentless':
        _drawFromOpponentGrave(player);
      case 'eredin_commander':
        _leaderHorn(player, CardRow.close);
      case 'eredin_bringer_of_death':
        _restoreFromGraveToHand(player);
      case 'eredin_destroyer':
        _eredinDestroyer(player);
      case 'eredin_king':
        _playWeatherFromDeck(player, null);
      case 'francesca_queen':
        _resolveRowScorch(player, CardRow.close);
      case 'francesca_beautiful':
        _leaderHorn(player, CardRow.ranged);
      case 'francesca_pureblood':
        _playWeatherFromDeck(player, Ability.frost);
      case 'francesca_hope':
        _resolveFrancescaHope(player);
      case 'crach_an_craite':
        _shuffleGravesIntoDecks(player);
      default:
        break;
    }
  }

  void _playWeatherFromDeck(PlayerState player, String? weatherAbility) {
    final candidates = player.deck
        .where(
          (c) => weatherAbility == null
              ? c.isWeather
              : c.abilities.contains(weatherAbility),
        )
        .toList();
    if (candidates.isEmpty) return;
    _placeWeather(candidates.first);
  }

  void _leaderHorn(PlayerState player, CardRow row) {
    final stateRow = state.rowState(player.index, row);
    if (stateRow.hasSpecial) return;
    stateRow.special = CardInstance(
      uid: engine.nextUid(),
      definition: CardRepository.byId('horn'),
      owner: player.index,
    );
  }

  void _drawFromOpponentGrave(PlayerState player) {
    final grave = state.players[state.opponentOf(player.index)].graveyard;
    final units = grave.where((c) => c.isUnit).toList()
      ..sort((a, b) => b.baseStrength.compareTo(a.baseStrength));
    if (units.isEmpty) return;
    final card = units.first;
    grave.remove(card);
    card.owner = player.index;
    player.hand.add(card);
    engine._emit(
      AbilityTriggered(
        player: player.index,
        ability: 'emhyr_relentless',
        cards: [card],
      ),
    );
  }

  void _restoreFromGraveToHand(PlayerState player) {
    final units = player.graveyard.where((c) => c.isUnit).toList()
      ..sort((a, b) => b.baseStrength.compareTo(a.baseStrength));
    if (units.isEmpty) return;
    final card = units.first;
    player.graveyard.remove(card);
    player.hand.add(card);
    engine._emit(
      AbilityTriggered(
        player: player.index,
        ability: 'eredin_bringer_of_death',
        cards: [card],
      ),
    );
  }

  void _eredinDestroyer(PlayerState player) {
    final discarded = discardOrder(player).take(2).toList();
    for (final card in discarded) {
      toGrave(card);
    }
    if (player.deck.isNotEmpty) {
      player.hand.add(player.deck.removeAt(0));
    }
    if (discarded.isNotEmpty) {
      engine._emit(
        AbilityTriggered(
          player: player.index,
          ability: 'eredin_destroyer',
          cards: discarded,
        ),
      );
    }
  }

  void _resolveFrancescaHope(PlayerState player) {
    final close = state.rowState(player.index, CardRow.close);
    final ranged = state.rowState(player.index, CardRow.ranged);
    for (final source in [close, ranged]) {
      final destination = source == close ? ranged : close;
      for (final card in List.of(source.cards)) {
        if (card.row != CardRow.agile) continue;
        final here = Scoring.cardStrength(state, source, card);
        final there = Scoring.cardStrength(state, destination, card);
        if (there > here) {
          source.cards.remove(card);
          insertSorted(destination, card);
        }
      }
    }
    engine._emit(AbilityTriggered(player: player.index, ability: 'francesca_hope'));
  }

  void _shuffleGravesIntoDecks(PlayerState player) {
    for (final p in state.players) {
      for (final card in List.of(p.graveyard)) {
        p.graveyard.remove(card);
        p.deck.add(card);
      }
      random.shuffle(p.deck);
    }
    engine._emit(AbilityTriggered(player: player.index, ability: 'crach_an_craite'));
  }

  // ---------------------------------------------------------------------------
  // Zone helpers
  // ---------------------------------------------------------------------------

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
