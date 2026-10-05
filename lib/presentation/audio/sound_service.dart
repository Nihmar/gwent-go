import '../../core/rules/game_event.dart';
import 'sound_cues.dart';
import 'sound_player.dart';

/// Turns game events into sound effects, honouring the sound setting.
///
/// The setting is read on every batch rather than captured, so muting takes
/// effect immediately without rebuilding anything.
class SoundService {
  SoundService({required this.player, bool Function()? isEnabled})
    : _isEnabled = isEnabled ?? (() => true);

  final SoundPlayer player;
  final bool Function() _isEnabled;

  /// Plays the cues of [events]; silent while sound is switched off.
  Future<void> handle(Iterable<GameEvent> events) async {
    if (!_isEnabled()) return;
    for (final cue in cuesFor(events)) {
      await player.play(cue);
    }
  }

  Future<void> dispose() => player.dispose();
}
