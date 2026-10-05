import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/card.dart';
import '../../core/models/player.dart';
import '../controllers/game_controller.dart';
import '../localization.dart';
import '../widgets/board_background.dart';
import '../widgets/board_widgets.dart';
import '../widgets/card_detail_dialog.dart';
import '../widgets/game/game_actions.dart';
import '../widgets/game/game_hand.dart';
import '../widgets/game/game_header.dart';
import '../widgets/game/game_overlays.dart';
import '../widgets/game/game_panels.dart';
import '../widgets/game/game_preview_panel.dart';
import '../widgets/game/game_score_table.dart';

/// The match screen: a widget-composed board that adapts to phone and desktop.
///
/// A match can be started fresh (from two decks) or resumed from a snapshot.
/// While playing, the snapshot is persisted so the app can be closed and the
/// match continued later.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.humanDeck,
    this.opponentDeck,
    this.difficulty = Difficulty.normal,
    this.hotseat = false,
    this.controller,
    this.snapshot,
    this.onFinished,
    this.onPersist,
    this.onReconnect,
    this.disconnectGrace = const Duration(seconds: 60),
  }) : assert(
         controller != null ||
             snapshot != null ||
             (humanDeck != null && opponentDeck != null),
         'Provide a controller, decks or a snapshot',
       );

  final DeckDefinition? humanDeck;
  final DeckDefinition? opponentDeck;
  final Difficulty difficulty;

  /// Two humans share this device; the board hides until the turn's player
  /// confirms the hand-over.
  final bool hotseat;

  /// Pre-built controller, used by the LAN lobby. The screen takes ownership
  /// and disposes it.
  final GameController? controller;

  /// When set, the match is restored instead of started.
  final Map<String, dynamic>? snapshot;

  /// Re-dials the opponent after a disconnect; absent in local matches and for
  /// the host, which can only wait.
  final Future<bool> Function()? onReconnect;

  /// How long a match waits for an absent opponent before giving up on it.
  final Duration disconnectGrace;

  /// Called once when the match ends, with the winner index or null for a draw.
  final void Function(int? winner)? onFinished;

  /// Called whenever the match should be persisted.
  final void Function(Map<String, dynamic> snapshot)? onPersist;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameController controller;
  bool _gameOverShown = false;
  Timer? _saveDebounce;
  Timer? _disconnectTimer;
  bool _disconnectShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final snapshot = widget.snapshot;
    controller =
        widget.controller ??
        (snapshot != null
            ? GameController.resume(snapshot, hotseat: widget.hotseat)
            : GameController(
                humanDeck: widget.humanDeck!,
                opponentDeck: widget.opponentDeck!,
                difficulty: widget.difficulty,
                opponentName: _opponentName(),
                hotseat: widget.hotseat,
              ));
    controller.addListener(_onChange);
    // An injected controller is already running (a lobby session).
    if (snapshot == null && widget.controller == null) controller.start();
  }

  String _opponentName() => switch (widget.opponentDeck!.faction) {
    CardFaction.monsters => 'Eredin Bréacc Glas',
    CardFaction.realms => 'Foltest',
    CardFaction.nilfgaard => 'Emhyr var Emreis',
    CardFaction.scoiatael => 'Francesca Findabair',
    CardFaction.skellige => 'Crach an Craite',
    _ => 'Opponent',
  };

  /// Tries to re-dial the host; the session keeps the match either way.
  Future<void> _reconnect() async {
    final reconnect = widget.onReconnect;
    if (reconnect == null) return;
    final reached = await reconnect();
    if (!mounted || reached) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.strings.reconnectFailed)),
    );
  }

  /// Runs the grace timer while the opponent is away.
  void _watchOpponent() {
    if (controller.opponentOnline) {
      _disconnectTimer?.cancel();
      _disconnectTimer = null;
      _disconnectShown = false;
      return;
    }
    if (_disconnectTimer != null || _disconnectShown) return;
    _disconnectTimer = Timer(widget.disconnectGrace, _onDisconnectElapsed);
  }

  void _onDisconnectElapsed() {
    _disconnectTimer = null;
    if (!mounted || controller.opponentOnline || controller.isGameOver) return;
    _disconnectShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOpponentGone());
  }

  Future<void> _showOpponentGone() async {
    if (!mounted) return;
    final strings = context.strings;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(strings.opponentGoneTitle),
        content: Text(strings.opponentGoneBody),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pause();
            },
            child: Text(strings.close),
          ),
        ],
      ),
    );
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    _watchOpponent();
    if (controller.isGameOver) {
      if (!_gameOverShown) {
        _gameOverShown = true;
        widget.onFinished?.call(controller.state.matchWinner);
        WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOver());
      }
      return;
    }
    _schedulePersist();
  }

  void _schedulePersist() {
    if (widget.onPersist == null) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), _persistNow);
  }

  void _persistNow() {
    if (!mounted || controller.isGameOver) return;
    final snapshot = controller.snapshot();
    if (snapshot == null) return;
    widget.onPersist?.call(snapshot);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _saveDebounce?.cancel();
      _persistNow();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveDebounce?.cancel();
    _disconnectTimer?.cancel();
    controller.removeListener(_onChange);
    controller.dispose();
    super.dispose();
  }

  Future<void> _showGameOver() async {
    if (!mounted) return;
    final strings = context.strings;
    final winner = controller.state.matchWinner;
    final title = winner == null
        ? strings.matchDrawn
        : winner == controller.human.index
        ? strings.winnerYou
        : strings.winnerOpponent(controller.opponent.name);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: GameScoreTable(state: controller.state),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.close),
          ),
        ],
      ),
    );
  }

  void _pause() {
    _saveDebounce?.cancel();
    _persistNow();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _persistNow();
      },
      child: Scaffold(
        body: BoardBackground(
          child: SafeArea(
            child: Stack(
              children: [
                // While hotseat play waits for the device to change hands the
                // board is not built at all, so no hand can leak.
                if (controller.pendingSeat != null)
                  PassDeviceOverlay(controller: controller)
                else ...[
                  wide ? _buildDesktop(context) : _buildPhone(context),
                  if (!controller.opponentOnline)
                    Positioned(
                      top: 8,
                      left: 12,
                      right: 12,
                      child: _DisconnectedBanner(
                        onLeave: _pause,
                        onReconnect: widget.onReconnect == null
                            ? null
                            : _reconnect,
                      ),
                    ),
                  if (controller.isMulligan)
                    MulliganOverlay(controller: controller),
                  if (controller.pendingChoice case final choice?)
                    ChoiceOverlay(controller: controller, choice: choice),
                  if (!wide &&
                      !controller.isMulligan &&
                      controller.pendingChoice == null &&
                      controller.selectedCard != null)
                    CardPreviewSheet(controller: controller),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone layout
  // ---------------------------------------------------------------------------

  Widget _buildPhone(BuildContext context) {
    const cardWidth = 42.0;
    return Column(
      children: [
        GameHeader(controller: controller, compact: true, onPause: _pause),
        GamePlayerStrip(controller: controller, opponent: true),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              children: [
                for (final row in [
                  CardRow.siege,
                  CardRow.ranged,
                  CardRow.close,
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: RowStrip(
                      state: controller.state,
                      owner: controller.opponent.index,
                      row: row,
                      cardWidth: cardWidth,
                      flashTick: controller.flashCounter,
                      flashColor: controller.flashColorFor,
                      leading: controller.opponent.isWinning,
                      onCardTap: (card) => showCardDetail(
                        context,
                        card.definition,
                        strength: card.currentStrength,
                      ),
                    ),
                  ),
                const MidRule(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: WeatherBand(state: controller.state, cardWidth: 28),
                ),
                const MidRule(),
                for (final row in [
                  CardRow.close,
                  CardRow.ranged,
                  CardRow.siege,
                ])
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: RowStrip(
                      state: controller.state,
                      owner: controller.human.index,
                      row: row,
                      cardWidth: cardWidth,
                      flashTick: controller.flashCounter,
                      flashColor: controller.flashColorFor,
                      leading: controller.human.isWinning,
                      onCardTap: (card) => showCardDetail(
                        context,
                        card.definition,
                        strength: card.currentStrength,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                GameHand(controller: controller, cardWidth: 76, scroll: true),
              ],
            ),
          ),
        ),
        GamePlayerStrip(controller: controller, opponent: false),
        GameActions(controller: controller, showHint: true),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop layout
  // ---------------------------------------------------------------------------

  Widget _buildDesktop(BuildContext context) {
    const cardWidth = 44.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 250,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                GamePlayerPanel(controller: controller, opponent: true),
                const SizedBox(height: 10),
                GamePlayerPanel(controller: controller, opponent: false),
              ],
            ),
          ),
        ),
        Expanded(child: _battlefield(cardWidth)),
        SizedBox(
          width: 300,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                GamePreviewPanel(controller: controller),
                const SizedBox(height: 10),
                GameScoreTable(state: controller.state),
                const SizedBox(height: 10),
                GameActions(controller: controller, vertical: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _battlefield(double cardWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          GameHeader(controller: controller, compact: true, onPause: _pause),
          const SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  for (final row in [
                    CardRow.siege,
                    CardRow.ranged,
                    CardRow.close,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: RowStrip(
                        state: controller.state,
                        owner: controller.opponent.index,
                        row: row,
                        cardWidth: cardWidth,
                        flashTick: controller.flashCounter,
                        flashColor: controller.flashColorFor,
                        leading: controller.opponent.isWinning,
                        onCardTap: (card) => showCardDetail(
                          context,
                          card.definition,
                          strength: card.currentStrength,
                        ),
                      ),
                    ),
                  const MidRule(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: WeatherBand(state: controller.state),
                  ),
                  const MidRule(),
                  for (final row in [
                    CardRow.close,
                    CardRow.ranged,
                    CardRow.siege,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: RowStrip(
                        state: controller.state,
                        owner: controller.human.index,
                        row: row,
                        cardWidth: cardWidth,
                        flashTick: controller.flashCounter,
                        flashColor: controller.flashColorFor,
                        leading: controller.human.isWinning,
                        onCardTap: (card) => showCardDetail(
                          context,
                          card.definition,
                          strength: card.currentStrength,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  GameHand(controller: controller, cardWidth: 88),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown while the opponent is unreachable.
///
/// The host keeps the match alive waiting for the guest to come back, so the
/// board stays playable-looking but locked; this banner explains why and offers
/// a way out.
class _DisconnectedBanner extends StatelessWidget {
  const _DisconnectedBanner({required this.onLeave, this.onReconnect});

  final VoidCallback onLeave;

  /// Present when this side can re-dial the opponent itself.
  final VoidCallback? onReconnect;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final scheme = Theme.of(context).colorScheme;
    final text = TextStyle(color: scheme.onErrorContainer);
    return Material(
      color: scheme.errorContainer,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.opponentDisconnected,
                    style: text.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    strings.waitingForOpponent,
                    style: text.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (onReconnect != null)
              FilledButton.tonal(
                onPressed: onReconnect,
                child: Text(strings.reconnect),
              ),
            TextButton(
              onPressed: onLeave,
              child: Text(strings.close),
            ),
          ],
        ),
      ),
    );
  }
}
