import '../../core/rules/game_event.dart';
import 'sound_player.dart';

/// The cue [event] asks for, or null when the event is silent.
///
/// Pure on purpose: the mapping is the part worth testing, and it can be
/// checked without any audio at all.
SoundCue? cueFor(GameEvent event) => switch (event) {
  // Start and turn changes pass silently: they carry no action of their own.
  MatchStarted() => null,
  TurnChanged() => null,
  CardPlayed() => SoundCue.cardPlayed,
  LeaderActivated() => SoundCue.leaderActivated,
  AbilityTriggered() => SoundCue.abilityTriggered,
  CardsDrawn() => SoundCue.cardsDrawn,
  WeatherChanged() => SoundCue.weatherChanged,
  PlayerPassed() => SoundCue.playerPassed,
  RoundEnded() => SoundCue.roundEnded,
  MatchEnded() => SoundCue.matchEnded,
};

/// Cues for a batch of events, in order, with the silent ones dropped.
List<SoundCue> cuesFor(Iterable<GameEvent> events) => [
  for (final event in events) ?cueFor(event),
];
