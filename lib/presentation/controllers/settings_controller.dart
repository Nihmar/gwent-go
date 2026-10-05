import 'package:flutter/foundation.dart';

import '../../core/data/card_repository.dart';
import '../../core/data/faction_catalog.dart';
import '../../core/models/card.dart';
import '../../core/models/player.dart';
import '../../core/persistence/profile_repository.dart';
import '../../core/rules/game_engine.dart';

/// Holds user settings, saved decks, statistics and the paused match.
///
/// Everything is persisted through [ProfileRepository] so the app can be closed
/// and resumed later. The controller is presentation state; the repository and
/// the store stay platform independent.
class SettingsController extends ChangeNotifier {
  SettingsController(this.repository);

  final ProfileRepository repository;

  AppSettings settings = AppSettings.defaults;
  MatchStats stats = MatchStats.empty;
  Map<String, dynamic>? savedMatch;
  bool loaded = false;

  final Map<CardFaction, DeckDefinition> _customDecks = {};

  DeckDefinition deckFor(CardFaction faction) =>
      _customDecks[faction] ?? CardRepository.defaultDeckFor(faction)!;

  bool get hasSavedMatch => savedMatch != null;

  Future<void> load() async {
    settings = await repository.loadSettings();
    stats = await repository.loadStats();
    final storedMatch = await repository.loadMatch();
    final validMatch = storedMatch != null && isValidMatchSnapshot(storedMatch);
    savedMatch = validMatch ? storedMatch : null;
    if (storedMatch != null && !validMatch) await repository.clearMatch();
    for (final faction in playableFactions) {
      final deck = await repository.loadDeck(faction);
      if (deck != null) _customDecks[faction] = deck;
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> setDifficulty(Difficulty difficulty) async {
    settings = settings.copyWith(difficulty: difficulty);
    notifyListeners();
    await repository.saveSettings(settings);
  }

  Future<void> setFaction(CardFaction faction) async {
    settings = settings.copyWith(faction: faction);
    notifyListeners();
    await repository.saveSettings(settings);
  }

  Future<void> saveDeck(DeckDefinition deck) async {
    _customDecks[deck.faction] = deck;
    settings = settings.copyWith(faction: deck.faction, deckId: deck.id);
    notifyListeners();
    await repository.saveDeck(deck);
    await repository.saveSettings(settings);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    settings = settings.copyWith(soundEnabled: enabled);
    notifyListeners();
    await repository.saveSettings(settings);
  }

  Future<void> toggleSound() => setSoundEnabled(!settings.soundEnabled);

  Future<void> recordMatch({
    required int? winner,
    required int humanIndex,
  }) async {
    stats = await repository.recordMatch(
      winner: winner,
      humanIndex: humanIndex,
    );
    await clearSavedMatch();
    notifyListeners();
  }

  Future<void> saveMatch(Map<String, dynamic> snapshot) async {
    savedMatch = snapshot;
    notifyListeners();
    await repository.saveMatch(snapshot);
  }

  Future<void> clearSavedMatch() async {
    savedMatch = null;
    notifyListeners();
    await repository.clearMatch();
  }

  Future<void> resetStats() async {
    await repository.resetStats();
    stats = MatchStats.empty;
    notifyListeners();
  }
}
