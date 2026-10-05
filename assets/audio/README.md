# Sound effects

Drop the cue files here using the names below. The directory is declared in
`pubspec.yaml`, so a new file with a matching name is picked up by the next
build without any code change.

| Cue | File |
| --- | --- |
| Card played | `card_played.mp3` |
| Leader activated | `leader_activated.mp3` |
| Ability triggered | `ability_triggered.mp3` |
| Cards drawn | `cards_drawn.mp3` |
| Weather changed | `weather_changed.mp3` |
| Player passed | `player_passed.mp3` |
| Round ended | `round_ended.mp3` |
| Match ended | `match_ended.mp3` |

The mapping lives in `lib/presentation/audio/sound_cue_assets.dart`.

MP3 is the safest format across Android, Linux and Windows. A cue whose file is
absent is simply silent: the audio is best-effort and must never break a match,
so the game ships before the effects are recorded.
