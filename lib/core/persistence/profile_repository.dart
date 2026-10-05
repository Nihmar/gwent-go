import 'dart:convert';

import '../models/card.dart';
import '../models/collection.dart';
import '../models/player.dart';
import '../data/deck_codec.dart';
import 'key_value_store.dart';

/// User preferences that survive restarts.
class AppSettings {
  const AppSettings({
    required this.difficulty,
    required this.faction,
    required this.soundEnabled,
  });

  final Difficulty difficulty;
  final CardFaction faction;
  final bool soundEnabled;

  static const defaults = AppSettings(
    difficulty: Difficulty.normal,
    faction: CardFaction.realms,
    soundEnabled: true,
  );

  AppSettings copyWith({
    Difficulty? difficulty,
    CardFaction? faction,
    bool? soundEnabled,
  }) => AppSettings(
    difficulty: difficulty ?? this.difficulty,
    faction: faction ?? this.faction,
    soundEnabled: soundEnabled ?? this.soundEnabled,
  );
}

/// Aggregate match statistics.
class MatchStats {
  const MatchStats({
    this.matches = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

  final int matches;
  final int wins;
  final int losses;
  final int draws;

  static const empty = MatchStats();

  double get winRate => matches == 0 ? 0 : wins / matches;

  MatchStats record({required int? winner, required int humanIndex}) {
    return MatchStats(
      matches: matches + 1,
      wins: wins + (winner == humanIndex ? 1 : 0),
      losses: losses + (winner != null && winner != humanIndex ? 1 : 0),
      draws: draws + (winner == null ? 1 : 0),
    );
  }
}

/// Reads and writes settings, decks, statistics and the paused match.
///
/// All values are stored as primitives through [KeyValueStore]; decks and
/// matches are JSON encoded. Unknown card ids are ignored on load so a catalog
/// change cannot crash the app.
class ProfileRepository {
  ProfileRepository(this._store);

  final KeyValueStore _store;

  static const _keyDifficulty = 'settings.difficulty';
  static const _keyFaction = 'settings.faction';
  static const _keySound = 'settings.sound';
  static const _keyMatches = 'stats.matches';
  static const _keyWins = 'stats.wins';
  static const _keyLosses = 'stats.losses';
  static const _keyDraws = 'stats.draws';
  static const _keyMatch = 'match.current';
  static const _keyCollection = 'collection.owned';

  String _deckKey(CardFaction faction) => 'deck.${faction.name}';

  Future<AppSettings> loadSettings() async {
    final difficulty = Difficulty.fromName(
      await _store.getString(_keyDifficulty) ?? '',
    );
    final faction = _factionFromName(await _store.getString(_keyFaction));
    return AppSettings(
      difficulty: difficulty,
      faction: faction,
      soundEnabled: await _store.getBool(_keySound) ?? true,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _store.setString(_keyDifficulty, settings.difficulty.name);
    await _store.setString(_keyFaction, settings.faction.name);
    await _store.setBool(_keySound, settings.soundEnabled);
  }

  Future<DeckDefinition?> loadDeck(CardFaction faction) async {
    final raw = await _store.getString(_deckKey(faction));
    if (raw == null || raw.isEmpty) return null;
    try {
      return deckFromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> saveDeck(DeckDefinition deck) async {
    await _store.setString(
      _deckKey(deck.faction),
      jsonEncode(deckToJson(deck)),
    );
  }

  Future<MatchStats> loadStats() async => MatchStats(
    matches: await _store.getInt(_keyMatches) ?? 0,
    wins: await _store.getInt(_keyWins) ?? 0,
    losses: await _store.getInt(_keyLosses) ?? 0,
    draws: await _store.getInt(_keyDraws) ?? 0,
  );

  Future<MatchStats> recordMatch({
    required int? winner,
    required int humanIndex,
  }) async {
    final stats = (await loadStats()).record(
      winner: winner,
      humanIndex: humanIndex,
    );
    await _store.setInt(_keyMatches, stats.matches);
    await _store.setInt(_keyWins, stats.wins);
    await _store.setInt(_keyLosses, stats.losses);
    await _store.setInt(_keyDraws, stats.draws);
    return stats;
  }

  Future<void> resetStats() async {
    await _store.remove(_keyMatches);
    await _store.remove(_keyWins);
    await _store.remove(_keyLosses);
    await _store.remove(_keyDraws);
  }

  Future<Map<String, dynamic>?> loadMatch() async {
    final raw = await _store.getString(_keyMatch);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  Future<void> saveMatch(Map<String, dynamic> snapshot) async {
    await _store.setString(_keyMatch, jsonEncode(snapshot));
  }

  Future<void> clearMatch() async {
    await _store.remove(_keyMatch);
  }

  Future<Collection> loadCollection() async {
    final raw = await _store.getString(_keyCollection);
    if (raw == null || raw.isEmpty) return Collection.full;
    try {
      return Collection.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return Collection.full;
    }
  }

  Future<void> saveCollection(Collection collection) async {
    await _store.setString(_keyCollection, jsonEncode(collection.toJson()));
  }
}

CardFaction _factionFromName(String? name) {
  for (final faction in CardFaction.values) {
    if (faction.name == name) return faction;
  }
  return AppSettings.defaults.faction;
}
