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
- collection browser and deck editor with rule validation (22 unit cards
  minimum, 10 special cards, 40 cards maximum) and a collection ownership model;
- settings, decks and match statistics persisted with `shared_preferences`;
- a match can be paused automatically, the app closed, and resumed from the
  home screen;
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
reused for future local or online multiplayer.

## Development

```bash
flutter pub get
flutter gen-l10n        # regenerate lib/l10n/generated
flutter test
flutter run -d linux    # or android / windows
flutter build linux     # release builds for the target platform
```

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
