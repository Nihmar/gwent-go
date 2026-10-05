import 'sound_player.dart';

/// Where each [SoundCue] lives in the bundled assets.
///
/// The files are optional: a missing one leaves the cue silent (see
/// `AssetSoundPlayer`). Keeping the mapping here means recording an effect is
/// only a matter of dropping a file into `assets/audio/` with the right name.
const Map<SoundCue, String> soundCueAssets = {
  SoundCue.cardPlayed: 'assets/audio/card_played.mp3',
  SoundCue.leaderActivated: 'assets/audio/leader_activated.mp3',
  SoundCue.abilityTriggered: 'assets/audio/ability_triggered.mp3',
  SoundCue.cardsDrawn: 'assets/audio/cards_drawn.mp3',
  SoundCue.weatherChanged: 'assets/audio/weather_changed.mp3',
  SoundCue.playerPassed: 'assets/audio/player_passed.mp3',
  SoundCue.roundEnded: 'assets/audio/round_ended.mp3',
  SoundCue.matchEnded: 'assets/audio/match_ended.mp3',
};

/// Asset path for [cue], or null when the cue is meant to stay silent.
String? assetForCue(SoundCue cue) => soundCueAssets[cue];
