# Multiplayer Plan

Status: **design draft**. No multiplayer code exists yet. This document turns the
"Future multiplayer considerations" of [architecture.md](architecture.md) into a
concrete plan: the recommended architecture, the engine work required before any
networking, a phased implementation order and the risks.

Per `AGENTS.md`, multiplayer is future scope. Nothing here should be implemented
until the corresponding phases are explicitly scheduled.

## Goals and non-goals

Goals for the first multiplayer release:

- Two humans, one match, each on their own device.
- Runs on Android, Linux and Windows; iOS/macOS achievable with the same design.
- Reuses the rules engine and the card catalog unchanged.
- A player never receives the opponent's hidden information (hand, deck order).
- A short disconnection does not destroy the match.
- Local (same-device) play works as a special case of the same architecture.

Non-goals for v1:

- More than two players, spectators, matchmaking, accounts, ranked play.
- Deterministic lockstep simulation (rejected, see below).
- Wi-Fi Direct and Bluetooth (designed for, implemented later).
- Anti-cheat against a malicious host (host is trusted; see "Trust model").

## Recommended architecture: host-authoritative

One peer is the **host**. The host owns the single authoritative `GameEngine`,
the RNG and the full `GameState`, validates every command and broadcasts the
resulting state to the guest. The guest renders the state it receives and sends
intents; it never simulates rules.

```
guest                         host
  |-- Command ------------->  validate + GameEngine.apply(command)
  |                           build projection for each seat
  |<-- StateView (guest) ---- |
  |<-- StateView (host) ----- |  (the host renders locally, no round-trip)
```

Why this model:

- The rules engine is synchronous and complete-turn based, so one authority
  resolves everything without negotiation.
- Hidden information stays on the host; the guest only needs a redacted view.
- The AI can play on the host without shipping extra state.
- No desync class of bugs: there is exactly one simulation.
- Reconnection is "send a fresh projection".

### Why not lockstep

A peer-to-peer lockstep design would have both peers run the engine and exchange
an ordered command log. It was rejected for v1 because:

- Hidden information (hands, deck order) still has to be handled per peer, so it
  buys little over host-authoritative.
- Both peers would need a bit-identical RNG. `dart:math`'s seeded `Random` is not
  guaranteed stable across Dart versions/platforms, so this is a portability
  risk rather than a property we can rely on.
- A malicious peer could deviate; detecting it needs state hashing and a
  dispute/rollback story.

Lockstep can be revisited later, ideally only after a custom PRNG (Phase 1) and
state hashing exist, because those are prerequisites anyway.

## Current state assessment

Already helpful:

- `lib/core` has no Flutter dependency, so networking code can live there.
- The engine separates state (`GameState`), actions and events
  (`game_event.dart`), and serializes a whole match (`game_engine_snapshot.dart`).
- `Scoring` and `DeckValidator` are pure.
- Randomness is injected (`GameRandom`) and seedable.

Blocking issues, each addressed by a phase below:

1. **Privileged local human.** ~~`GameState.human`, `GameEngine.human`/`opponent`
   and `isHumanTurn`/`isOpponentTurn` assume exactly one human seat (index 0).~~
   Done: the core is seat agnostic; `GameController.localSeat` marks the local
   seat in the presentation layer.
2. **Opponent mulligan is automatic.** ~~`startMatch()` calls
   `_mulliganOpponent()`, and `redraw()` rejects any `playerIndex != human.index`.~~
   Done: `redraw`/`finishMulligan` are per seat with a redraw budget on
   `PlayerState`; the round starts once every seat has confirmed. The AI seats'
   redraws are driven by the controller.
3. **Scoia'tael first-player choice defaults to the local human.** Done: a lone
   Scoia'tael seat decides through `ChooseFirstPlayerCommand`; the engine
   exposes the pending choice.
4. **Opponent identity is baked into the engine.** Done: `opponentName` is gone
   from the engine and the snapshot; names live on `PlayerState` and are set by
   the presentation/lobby.
5. **`dart:math` RNG.** Done: `GameRandom` is an in-core xorshift128 seeded
   through SplitMix32, always recording its seed.
6. **No command objects.** Done: `GameCommand`/`CommandResult` carry uids and
   rejection reasons, and `GameEngine.apply` is the single mutation path.
7. **No fog of war.** `GameState` and `encodeMatch` include both hands and the
   full deck order. A guest must receive a redacted projection.
8. **Events hold object references.** `GameEvent`s are not serializable. Rather
   than serializing them, ship projections and let the client re-derive
   animations from state changes, or serialize a small event DTO later.
9. **No versioning.** Nothing rejects a peer whose card catalog or protocol
   differs.
10. **AI runs from the Flutter controller.** `GameController._maybeRunAi` owns the
    opponent turn loop with `Future.delayed`; in multiplayer the host session
    must drive it, and the controller must become transport-agnostic.

## Phases

Each phase is independently mergeable and testable. Phases 1–4 contain **no
networking** and improve the current single-player code too.

### Phase 1 — Engine as a command processor *(done)*

Goal: every state mutation is a serializable command applied by the engine.

- Add `lib/core/rules/game_command.dart` with a sealed `GameCommand`
  (`PlayCard`, `ActivateLeader`, `Pass`, `Redraw`, `FinishMulligan`,
  `ChooseFirstPlayer`) carrying ids (`cardUid`, `targetUid`) and a `CardRow?`.
- Add `CommandResult` (`Accepted` / `Rejected(CommandRejection reason)`) and
  `GameEngine.apply(GameCommand)`; route the existing public methods through it.
- Rejection reasons are language-independent enums, localized by the UI
  (same pattern as `DeckIssue`).
- Replace `dart:math` with a documented 32-bit PRNG (e.g. xorshift128 seeded via
  SplitMix32) that keeps the `nextInt`/`nextDouble`/`pick`/`chance`/`shuffle`
  surface. Implement `shuffle` with Fisher–Yates over `nextInt`, not
  `List.shuffle`.
- Remove the privileged human: delete `GameState.human`, drop `opponentName` from
  the engine, and move `human`/`opponent`/turn predicates to the presentation or
  session layer (`localSeat`).
- Make the mulligan per seat: `RedrawCommand(player, card)` and
  `FinishMulliganCommand(player)`; `startMatch` no longer plays the opponent's
  mulligan. The AI mulligan becomes an explicit decision made by whatever drives
  the opponent seat.
- `ChooseFirstPlayerCommand` for Scoia'tael.

Tests: command validation (illegal commands rejected with the right reason), a
scripted mulligan for both seats, and a **determinism test** that replays the
same seed + command list and asserts an identical state hash.

### Phase 2 — Fog of war and versioning *(done)*

Goal: a peer can be given a view of the match that never contains hidden data.

- Add `GameState.projectFor(int seat)` (or a `MatchView` DTO) that removes the
  opponent hand and deck order, keeping public zones (battlefields, weather,
  graveyards, row specials) intact.
- Expose only counts for hidden zones. The exact representation (empty lists plus
  `handCount`/`deckCount`, or a dedicated view model) is an open decision; see
  "Open questions".
- Add a serialized projection codec and a **projection test** asserting that no
  hidden card id ever appears in the payload.
- Add `catalogHash` (hash of every card id + abilities + `maxCopies`) and a
  `protocolVersion`; refuse a peer that does not match.
- Add a deterministic `stateHash` for debugging and future verification.

### Phase 3 — Session layer (transport-agnostic) *(done)*

Goal: a match can be hosted and joined over an abstract transport, in memory.

- Add `lib/core/session/` with a narrow `MatchTransport`
  (`Stream<Map<String, Object?>> incoming`, `void send(...)`, `Future close()`).
- Define the message set: `hello`, `welcome`, `reject`, `deck`, `start`,
  `command`, `rejected`, `view`, `resync`, `ping`, `pong`, `bye`.
- Implement `HostSession` (owns the engine and RNG, applies commands, projects
  per seat, drives an optional AI seat) and `ClientSession` (sends commands,
  exposes views and lobby state).
- Commands carry a monotonically increasing `seq` for idempotent retries.
- Keep everything Flutter-free and JSON-friendly.

Tests: an in-memory loopback pair plays a full match; illegal commands from the
client are rejected; a mid-match transport drop can be resumed with a `resync`.

### Phase 4 — Hotseat (local multiplayer)

Goal: validate Phases 1–3 without any networking.

- Two humans alternate on one device. A "pass the device" screen hides the next
  player's hand between turns.
- The projector is used to switch perspectives, so hidden information is exercised
  in the simplest possible setting.
- No transport is involved: the "session" is in-process.

Exit criteria: a full two-human match on one device, with no privileged seat and
no hand leakage on the transition screen.

### Phase 5 — Presentation integration

Goal: the UI works with a local or remote driver behind the same interface.

- Split `GameController` into:
  - a **view controller** owning UI state (selection, pending choices, preview)
    that reads a `MatchView`;
  - a **turn driver**: `LocalAiDriver` (today's behavior), `HotseatDriver`,
    `SessionDriver` (remote).
- Remove `Future.delayed` AI scheduling from the widget-facing controller.
- Add lobby screens: create/join, ready check, deck pick, difficulty/AI slot,
  rematch.
- All new strings go through the ARB/localization stack.

### Phase 6 — LAN transport and discovery

Goal: two devices on the same network can play.

- Implement `MatchTransport` over TCP (newline-delimited JSON) or WebSocket.
- Discovery: UDP broadcast/multicast announcement, with a manual "enter host
  address" fallback. mDNS is an alternative if a maintained package is acceptable.
- Keep platform details (`network_info_plus`, sockets, permissions) behind
  `lib/platform/` so core stays clean.
- Android: LAN permissions and lifecycle handling; Linux/Windows: no special
  permissions.

### Phase 7 — Reconnection and robustness

- Reconnect handshake: guest proves its seat, host replies with a fresh
  projection plus a `resync` marker.
- Disconnect handling: pause the match, show a banner, allow cancel; drop the
  match after a configurable window.
- Optional turn timer (decision needed; probably off for v1).

### Phase 8 — Future transports and features

- Wi-Fi Direct (Android) and Bluetooth behind the same `MatchTransport`.
- Spectators, 3+ players, rematch series, ranked — explicitly out of scope until
  the above is stable.

## Trust model

The host is trusted: it can see both hands and can, in principle, cheat. This is
acceptable for friendly LAN and local play. Hardening (commitments, verifiable
shuffles, server hosting) is out of scope and should be documented rather than
half-implemented.

## Compatibility and versioning

Every connection checks:

- `protocolVersion` — message/command compatibility.
- `catalogHash` — the exact card set and abilities, so ids and rules agree.
- `rulesVersion` — optional, for balance changes that keep the catalog stable.

Mismatches are rejected in the lobby with a localized message.

## Testing strategy

- **Engine**: command validation, per-seat mulligan, determinism replay
  (seed + command log -> identical state hash).
- **Projection**: no hidden card id is serialized for the opponent seat.
- **Session**: in-memory host+client full match, rejection paths, resync.
- **Transport**: a fake transport with drops/reordering; the real transport gets
  an integration test on loopback.
- **UI**: hotseat perspective switch and lobby flows as widget tests.

## Risks

- **RNG portability.** Mitigated in Phase 1 with an in-core PRNG.
- **Hidden-info leaks.** Any new event or DTO must be checked against the
  projection tests.
- **Save-format churn.** The local snapshot format will change (commands,
  versioning); keep `version` and migrate or discard old snapshots as with the
  current `isValidMatchSnapshot` flow.
- **Mobile lifecycle.** Android backgrounding can suspend sockets; reconnection
  (Phase 7) must be in place before LAN play feels reliable.
- **Scope creep.** Keep v1 to two players, one match, host-authoritative.

## Open questions

1. **Projection representation**: reuse a redacted `GameState` (with counts for
   hidden zones) or introduce a dedicated `MatchView`? Reuse is cheaper; a view
   model is cleaner and avoids the engine ever seeing placeholders.
2. **Who submits the first-player choice** for Scoia'tael, and does it happen in
   the mulligan phase or before it?
3. **Local storage of identity**: ephemeral per-session name or a persisted
   profile?
4. **Discovery mechanism**: UDP broadcast first, or mDNS from the start?
5. **Turn timers**: none for v1, or a generous timeout to reclaim dropped seats?
6. **AI in a network match**: can the host fill the second seat with an AI while
   a guest joins as a spectator? (Out of scope, but affects the lobby shape.)
