/// Short sound effects a match can ask for.
///
/// A cue names what happened, not which file to play, so the mapping to actual
/// assets stays in the player implementation and the game logic stays free of
/// audio.
enum SoundCue {
  cardPlayed,
  leaderActivated,
  abilityTriggered,
  cardsDrawn,
  weatherChanged,
  playerPassed,
  roundEnded,
  matchEnded,
}

/// Plays [SoundCue]s.
///
/// Injected rather than global so the presentation layer stays testable and a
/// platform without audio can fall back to [SilentSoundPlayer].
abstract interface class SoundPlayer {
  Future<void> play(SoundCue cue);

  Future<void> dispose();
}

/// Plays nothing; the default until an audio backend is supplied.
class SilentSoundPlayer implements SoundPlayer {
  const SilentSoundPlayer();

  @override
  Future<void> play(SoundCue cue) async {}

  @override
  Future<void> dispose() async {}
}
