# Gwent Go — UI mockup

Static HTML/CSS concept of the application UI on Android and desktop
(Linux / Windows). It is a **design reference**, not app code: nothing here
runs in the Flutter project.

## Viewing

Open `index.html` in a browser (double-click works — no server, no build step).
The gallery embeds every screen in a device frame at its real viewport size and
links to each screen full size.

| Screen | Viewport | File |
| --- | --- | --- |
| Android — home | 412 × 915 | `screens/android-menu.html` |
| Android — match | 412 × 915 | `screens/android-board.html` |
| Desktop — home | 1280 × 800 | `screens/desktop-menu.html` |
| Desktop — match | 1280 × 800 | `screens/desktop-board.html` |
| Desktop — deck editor | 1280 × 800 | `screens/desktop-decks.html` |

## Asset dependency

Card artwork, faction shields, round gems, ability/row icons and the power
badge sprites are **referenced** from the ignored reference checkout
(`gwent-classic-enhanced/img/`) rather than copied, so nothing large is
duplicated in this repository. If that folder is missing, the screens render
with blank images.

Everything else — card frames, name banners, board rows, weather band, piles,
player panels — is drawn with plain CSS, mirroring the widget-composed board
required by `AGENTS.md`. The card power badge places the reference sprite with
fixed sprite-sheet math (content sits at 15,14–125,125 in a 215 × 215 canvas).

## Design intent

- **Material 3 chrome** on a gold-on-charcoal dark scheme: top app bars,
  navigation rail (desktop), segmented buttons, chips, FAB-sized actions.
- **Phone layouts are portrait-first**: the home screen uses the standard M3
  layout; the match view is immersive fullscreen (system bars hidden) with a
  scrollable hand.
- **Desktop adds context**: player rails with leader/deck/graveyard state, a
  card preview panel with ability text, a match score table, and a
  three-column deck editor (collection, deck by row, stats/leader/difficulty).
- **Difficulty is first class**: Easy / Normal / Hard on the home screen, in
  the deck editor and as a chip on the opponent panel during a match.
- **Rules surface in the UI**: Biting Frost is shown freezing both close rows
  (heroes unaffected), Commander's Horn doubles the opponent's siege row, and
  round gems / pass state are visible at all times.
- **English only, localizable**: no Italian strings, no hard-coded game text in
  layout logic.

Interactions sketched in the mockup: on desktop, clicking a hand card updates
the preview panel (small inline script); on phones, the hand scrolls
horizontally and the selected card is lifted.

## Checks

No browser is required to sanity-check the mockup:

```bash
python3 tools/check_assets.py screens/*.html index.html   # referenced files exist
python3 tools/check_classes.py                            # no orphan CSS classes
python3 tools/check_structure.py                          # tag balance
```

`desktop-board.html` and `desktop-decks.html` are slightly over the ~500 line
guideline by design: the repetitive card markup keeps each screen a
self-contained file that can be opened and inspected directly.
