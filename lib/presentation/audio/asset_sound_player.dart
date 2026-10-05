import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'sound_cue_assets.dart';
import 'sound_player.dart';

/// Plays the bundled cue files through `audioplayers`.
///
/// Audio is best-effort: a cue whose asset is missing stays silent, and a
/// playback failure never propagates into the match. That lets the game ship
/// before the effects are recorded - dropping a file into `assets/audio/` is
/// all it takes to enable one.
class AssetSoundPlayer implements SoundPlayer {
  AssetSoundPlayer({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// One player per cue, so two different effects do not interrupt each other.
  final Map<SoundCue, AudioPlayer> _players = {};

  /// Cues whose asset was not found, so the bundle is only probed once.
  final Set<SoundCue> _missing = {};

  @override
  Future<void> play(SoundCue cue) async {
    final asset = assetForCue(cue);
    if (asset == null || _missing.contains(cue)) return;
    if (!await _exists(asset)) {
      _missing.add(cue);
      return;
    }
    if (!await _exists(asset)) {
      _missing.add(cue);
      return;
    }
    try {
      var player = _players[cue];
      if (player == null) {
        player = AudioPlayer();
        _players[cue] = player;
        await player.setReleaseMode(ReleaseMode.stop);
      }
      await player.stop();
      await player.play(AssetSource(_bundlePath(asset)));
    } on Object {
      // The codec or the platform backend may refuse a file; a sound effect
      // must never break the match.
    }
  }

  Future<bool> _exists(String asset) async {
    try {
      await _bundle.load(asset);
      return true;
    } on Object {
      return false;
    }
  }

  /// `AssetSource` paths are relative to the asset root.
  String _bundlePath(String asset) =>
      asset.startsWith('assets/') ? asset.substring(7) : asset;

  @override
  Future<void> dispose() async {
    final players = _players.values.toList();
    _players.clear();
    for (final player in players) {
      await player.dispose();
    }
  }
}
