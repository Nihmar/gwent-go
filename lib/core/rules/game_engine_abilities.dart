part of 'game_engine.dart';

/// Where a card currently lives, used when moving it between zones.
enum _Zone { hand, deck, grave, row, special, weather, none }

/// Card placement and on-battlefield ability resolution.
///
/// Split from [GameEngine] to keep both files cohesive; sharing the library
/// lets the resolver manipulate the engine's private state directly. Leader
/// abilities and zone helpers live in the companion part files.
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

  RowState rowForCard(
    CardInstance card,
    int playerIndex, {
    CardRow? targetRow,
  }) {
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
    if (state.weatherCards.any((c) => _sameWeatherType(c, card))) {
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

  /// Weather effects a card applies (a Storm applies rain and fog).
  Set<String> _weatherTypes(CardInstance card) =>
      card.abilities.where(Ability.isWeather).toSet();

  /// Weather cards are unique per effect profile, not per display name, so a
  /// card keeps behaving like the effect it represents even if it is renamed.
  bool _sameWeatherType(CardInstance a, CardInstance b) {
    final left = _weatherTypes(a);
    final right = _weatherTypes(b);
    return left.length == right.length && left.containsAll(right);
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
          final drawn = draw(player, 2);
          if (drawn > 0) {
            engine._emit(CardsDrawn(player: player.index, count: drawn));
          }
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
    // The ranged Berserker becomes the Young Vildkaarl, the close one becomes
    // the full Vildkaarl: the row carries the distinction, not the name.
    final targetId = card.row == CardRow.ranged
        ? 'young_vildkaarl'
        : 'vildkaarl';
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
    final medics = candidates
        .where((c) => c.hasAbility(Ability.medic))
        .toList();
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
      targets.addAll(
        row.cards.where((c) => c.isUnit && c.owner == player.index),
      );
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
}
