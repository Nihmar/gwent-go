# Gwent Go

A cross-platform Flutter implementation of **Gwent**, the card game from
*The Witcher 3: Wild Hunt*.

The project targets Android, Linux and Windows. iOS and macOS are planned for
the future. The reference JavaScript implementation is used only as a source of
gameplay knowledge and card artwork; the architecture here is independent
(see [`AGENTS.md`](AGENTS.md)).

## Status

The game is playable end to end against the computer:

- full card catalog (214 cards) with weather, Tight Bond, Morale,
  Commander's Horn, Medic, Muster, Spy, Decoy, Scorch, Avenger, Berserker and
  Agile behaviour;
- faction perks for all five factions and every leader ability;
- three mutually exclusive rounds, passing, card advantage and round gems;
- three opponent difficulties (`Easy`, `Normal`, `Hard`) driving a heuristic AI;
- responsive, widget-composed Material 3 board for phone and desktop;
- a touch-first deck editor: a persistent summary bar with counts, strength and
  validation, ability labels on every collection card and an ability sheet on
  long-press, plus quantity steppers instead of tap-to-remove;
- deck building rules (22 unit cards minimum, 10 special cards, 40 cards
  maximum) with a collection ownership model;
- settings, decks and match statistics persisted with `shared_preferences`;
- a match can be paused automatically, the app closed, and resumed from the
  home screen;
- two humans on one device (hotseat) and host-authoritative LAN play over TCP,
  with UDP discovery, a manual address fallback and reconnection after a drop;
- match sound effects through an asset-backed `SoundPlayer`, honouring the
  persisted sound toggle (the cue files are not recorded yet; see
  `assets/audio/README.md`);
- English UI built on Flutter's localization stack (easy to translate).

## Project layout

```
lib/
  core/                 platform-independent game core
    models/             cards, players, rows, match state
    data/               card catalog, factions, default decks, repository
    rules/              scoring, abilities, turn/round engine, events
    ai/                 evaluator and the three opponent personalities
  presentation/         Flutter layer
    theme/              Material 3 theme and Gwent palette
    widgets/            cards, rows, piles, selectors
    screens/            home, game board, deck editor
    controllers/        engine ⇄ widget-tree bridge
  l10n/                 ARB sources and generated localizations
assets/                 card artwork, icons and faction art
mockups/                static HTML/CSS design reference
tool/                   generators for the catalog and default decks
```

The rules engine has no Flutter dependency: it can be unit tested on its own and
supports local (hotseat) and LAN play through the same command interface.

## Development

```bash
flutter pub get
flutter gen-l10n        # regenerate lib/l10n/generated
flutter test
flutter run -d linux    # or android / windows
flutter build linux     # release builds for the target platform
```

### Android release signing

Release APKs and bundles are signed with a dedicated keystore when
`android/key.properties` exists; both it and the keystore are git-ignored.
Without them Gradle falls back to the debug key so contributors can still run
`flutter build apk --release`.

`android/key.properties`:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=gwentgo
storeFile=gwent-go-release.jks
```

`storeFile` is relative to `android/app/`. Generate a keystore with:

```bash
keytool -genkeypair -v \
  -keystore android/app/gwent-go-release.jks \
  -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 \
  -alias gwentgo \
  -storepass <password> -keypass <password>
```

Keep the keystore and its passwords backed up somewhere safe: losing them means
the published app can no longer be updated. `flutter build appbundle` is the
recommended format for Play Store submissions.

The Android and Linux application ids are `dev.nihmar.gwentgo`. The iOS, macOS
and Windows runners still carry the generated `com.example` placeholders and
should be updated if those platforms are ever enabled.

## Assets

Card artwork and icon sprites are bundled under `assets/`. They originate from
the reference game art and are copied into the repository so the application
never depends on the ignored `gwent-classic-enhanced/` checkout at runtime.

The card catalog and default decks under `lib/core/data/` are generated from the
reference data by `tool/generate_card_catalog.js` and
`tool/generate_default_decks.js`.

## Documentation

- [`docs/architecture.md`](docs/architecture.md) — layers, engine design,
  localization and future multiplayer considerations.
- [`mockups/README.md`](mockups/README.md) — the static UI design reference.

## License

Game names, characters and artwork belong to their respective owners. This
repository is a personal, non-commercial re-implementation.
