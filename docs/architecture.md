# Architecture

This document describes how Gwent Go is organised and records the decisions that
matter for the project's stated goals: maintainability, cross-platform support,
localization and future multiplayer.

## Layers

```
presentation (Flutter)     screens, widgets, theme, controllers
        │  reads state, dispatches actions
core/rules                 GameEngine, scoring, abilities, AI
core/models                cards, players, rows, match state
core/data                  card catalog, factions, decks, repository
```

The dependency direction is one way: `presentation → core`. The core never
imports Flutter, which is what makes the engine testable and reusable.

### core/models

Pure data. `CardDefinition` is immutable and shared; `CardInstance` carries the
mutable per-match state (owner, current strength, Monsters' `noRemove`). Cards
are identified by a stable, language-independent string id (the reference
artwork file name). Ability identifiers such as `medic` or `scorch_c` are
likewise language independent.

### core/rules

`GameEngine` is the authoritative state machine. It is **synchronous**: every
public action (`playCard`, `pass`, `activateLeader`) resolves a complete turn
and records `GameEvent`s that the UI drains with `takeEvents()`. Round
transitions, faction perks, weather, and card abilities are all resolved inside
the engine.

Strength computation lives in `Scoring` and is pure; `Scoring.refresh` writes the
displayed values back onto the state. This mirrors classic Gwent formulas:
weather clamps units to 1, Tight Bond multiplies by the number of same-named
bonded cards, Morale adds +1 per other Morale card, and Commander's Horn doubles
the row.

Card abilities are grouped in `game_engine_abilities.dart`, a `part` of the
engine so placement helpers keep access to engine-private state while both files
stay small and cohesive.

### core/ai

`AiEvaluator` measures the exact value of a card by temporarily mutating the
board (and always restoring it), then the three personalities in `ai_players.dart`
select differently:

- **Easy** — greedy, plays its strongest card, never passes or uses a leader
  while it can still act.
- **Normal** — weighs every option and samples one proportionally, using the
  reference heuristics.
- **Hard** — deterministic greedy play plus card-advantage aware passing and
  round-close detection.

Difficulty only changes decision-making; the rules are identical at every level.

### presentation

`GameController` bridges the engine to the widget tree. It owns the human's
interaction state (selected card, pending row/target choice) and drives the AI
with short delays so its moves are readable. Screens are responsive: the home
screen, board and deck editor each switch between a phone and a desktop layout
at a width breakpoint.

The board is composed entirely from widgets (`Row`, `Container`, `Stack`,
`Image`); only card artwork and icon sprites are raster assets.

## Persistence

The core depends on a tiny `KeyValueStore` interface only. The Flutter layer
provides `SharedPreferencesStore`; tests use `InMemoryKeyValueStore`.
`ProfileRepository` builds on it to store settings, per-faction decks,
aggregate statistics and the paused match.

A match is serialized by `GameEngine.toJson` / `GameEngine.fromJson`: card
instances are stored once in a flat registry (id plus per-instance flags) and
every zone references them by `uid`. Only card ids are persisted, so a catalog
change cannot desynchronise a snapshot; unknown ids make the snapshot invalid
and it is discarded on load. The RNG seed is stored and the deck order is
explicit, so a resumed match keeps drawing the same cards.

`GameScreen` persists the snapshot through `onPersist` (debounced after each
change, and immediately when the app is backgrounded or the match is paused).
`HomeScreen` shows **Continue match** while a snapshot exists; finishing a match
records the statistics and clears the snapshot.

## Deck building

`DeckValidator` (core) enforces the deck rules and returns language-independent
[DeckIssue] values that the UI localizes: at least 22 unit cards (heroes count),
at most 10 special cards and at most 40 cards in total, cards restricted to the
faction plus neutral/special/weather, and copy limits respected. The deck editor
and the home screen both refuse to start an invalid deck.

`Collection` models ownership. It defaults to owning every card up to its
`maxCopies`, and explicit entries can restrict that (and are persisted), so a
future progression system can hook in without changing the validator or the
editor. There is no way to acquire cards yet.

## Localization

All user-facing strings come from `lib/l10n/app_en.arb` through Flutter's
`gen-l10n`. Card *names* are proper nouns and are not localized; card and ability
*descriptions* are looked up by their language-independent ability id via the
`GwentLocalizations` extension. Adding a language means adding an ARB file and a
locale entry — no rules or UI code changes.

## Determinism

`GameRandom` wraps `dart:math`'s `Random` and accepts an optional seed. Tests use
seeded engines so full matches are reproducible. The engine emits events rather
than performing animations, so replaying an action log would reproduce the same
state.

## Future multiplayer considerations

Multiplayer is intentionally **not** implemented, but the following were kept in
mind and should be revisited when it is:

1. **Authoritative state and actions.** The engine already separates state
   (`GameState`), actions (`playCard`, `pass`, `activateLeader`) and events.
   A host/client model could ship actions to an authority and broadcast events.
2. **Deterministic evaluation.** Seeded randomness makes a deterministic replay
   feasible; hidden information (hands, decks) can stay server-side.
3. **Host/client vs peer-to-peer.** A host/client model fits the current
   synchronous engine best, since one side owns the deck shuffles and AI. A pure
   peer-to-peer lockstep design would require a shared action log and a
   fairness rule for simultaneous choices.
4. **Transport.** LAN, Wi-Fi Direct and Bluetooth are all plausible. No
   transport abstraction has been introduced yet to avoid speculative code; the
   recommendation is to add a narrow `MatchTransport` interface when the first
   transport is implemented.
5. **Discovery, identity, reconnection.** Not designed yet. Player identity and
   a reconnect handshake should be specified alongside the transport.

## Known limitations / follow-ups

- **Rule choices for the human:** target selection is implemented for Decoy,
  Medic, Eredin's Destroyer of Worlds (discard two, then draw one), Emhyr's
  Relentless and Eredin's Bringer of Death (pick from a discard pile). Emhyr's
  Emperor emits the revealed cards as an event but does not show them in a
  dedicated dialog yet.
- **King Bran** is described as "units only lose half their Strength in bad
  weather"; the reference implementation does not apply it, so this project
  implements the ceiled half as the intended behaviour.
- **Sound and music** are not implemented; the setting is persisted but has no
  effect yet.
- **No progression:** `Collection` can restrict ownership, but there is no way
  to acquire cards yet, so it defaults to owning every card up to its copy
  limit.
- **Display font:** the mockup uses *Cinzel*; the app currently uses the
  platform serif fallback to avoid shipping a font dependency. Bundling Cinzel
  is a small follow-up.
- **Assets:** card artwork is copied from the reference art into `assets/`. If
  the upstream art changes, the copied files must be refreshed manually.
