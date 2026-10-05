part of 'game_engine.dart';

/// Leader abilities.
///
/// Kept as an extension so [GameEngine] can stay the single entry point while
/// the (large) set of leader implementations lives in its own file.
extension _LeaderAbilities on _AbilityResolver {
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
        final hand = List.of(
          state.players[state.opponentOf(player.index)].hand,
        );
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
    )..temporary = true;
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
    engine._emit(
      AbilityTriggered(player: player.index, ability: 'francesca_hope'),
    );
  }

  void _shuffleGravesIntoDecks(PlayerState player) {
    for (final p in state.players) {
      for (final card in List.of(p.graveyard)) {
        p.graveyard.remove(card);
        p.deck.add(card);
      }
      random.shuffle(p.deck);
    }
    engine._emit(
      AbilityTriggered(player: player.index, ability: 'crach_an_craite'),
    );
  }
}
