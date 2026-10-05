import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/card.dart';
import '../../core/models/player.dart';
import '../controllers/game_controller.dart';
import '../localization.dart';
import '../widgets/board_background.dart';
import '../widgets/board_widgets.dart';
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
    this.snapshot,
    this.onFinished,
    this.onPersist,
  }) : assert(
         snapshot != null || (humanDeck != null && opponentDeck != null),
         'Provide decks or a snapshot',
       );

  final DeckDefinition? humanDeck;
  final DeckDefinition? opponentDeck;
  final Difficulty difficulty;

  /// When set, the match is restored instead of started.
  final Map<String, dynamic>? snapshot;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final snapshot = widget.snapshot;
    controller = snapshot != null
        ? GameController.resume(snapshot)
        : GameController(
            humanDeck: widget.humanDeck!,
            opponentDeck: widget.opponentDeck!,
            difficulty: widget.difficulty,
            opponentName: _opponentName(),
          );
    controller.addListener(_onChange);
    if (snapshot == null) controller.start();
  }

  String _opponentName() => switch (widget.opponentDeck!.faction) {
    CardFaction.monsters => 'Eredin Bréacc Glas',
    CardFaction.realms => 'Foltest',
    CardFaction.nilfgaard => 'Emhyr var Emreis',
    CardFaction.scoiatael => 'Francesca Findabair',
    CardFaction.skellige => 'Crach an Craite',
    _ => 'Opponent',
  };

  void _onChange() {
    if (!mounted) return;
    setState(() {});
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
    widget.onPersist?.call(controller.snapshot());
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
                wide ? _buildDesktop(context) : _buildPhone(context),
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
                      leading: controller.opponent.isWinning,
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
                      leading: controller.human.isWinning,
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
                        leading: controller.opponent.isWinning,
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
                        leading: controller.human.isWinning,
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
