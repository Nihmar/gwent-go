import 'package:flutter/material.dart';

import '../../core/data/faction_catalog.dart';
import '../../core/models/card.dart';
import '../../core/models/game_state.dart';
import '../../core/models/player.dart';
import '../../core/rules/scoring.dart';
import '../controllers/game_controller.dart';
import '../localization.dart';
import '../theme/gwent_colors.dart';
import '../widgets/board_background.dart';
import '../widgets/board_widgets.dart';
import '../widgets/gwent_card.dart';

/// The match screen: a widget-composed board that adapts to phone and desktop.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.humanDeck,
    required this.opponentDeck,
    required this.difficulty,
  });

  final DeckDefinition humanDeck;
  final DeckDefinition opponentDeck;
  final Difficulty difficulty;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller;
  bool _gameOverShown = false;

  @override
  void initState() {
    super.initState();
    controller = GameController(
      humanDeck: widget.humanDeck,
      opponentDeck: widget.opponentDeck,
      difficulty: widget.difficulty,
      opponentName: _opponentName(),
    );
    controller.addListener(_onChange);
    controller.start();
  }

  String _opponentName() {
    final faction = widget.opponentDeck.faction;
    return switch (faction) {
      CardFaction.monsters => 'Eredin Bréacc Glas',
      CardFaction.realms => 'Foltest',
      CardFaction.nilfgaard => 'Emhyr var Emreis',
      CardFaction.scoiatael => 'Francesca Findabair',
      CardFaction.skellige => 'Crach an Craite',
      _ => 'Opponent',
    };
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    if (controller.isGameOver && !_gameOverShown) {
      _gameOverShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOver());
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    controller.dispose();
    super.dispose();
  }

  Future<void> _showGameOver() async {
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
        content: _ScoreTable(state: controller.state),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      body: BoardBackground(
        child: SafeArea(
          child: Stack(
            children: [
              wide ? _buildDesktop(context) : _buildPhone(context),
              if (controller.isMulligan) _MulliganOverlay(controller: controller),
              if (controller.pendingChoice case final choice?)
                _ChoiceOverlay(controller: controller, choice: choice),
            ],
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
        _Header(controller: controller),
        _PlayerStrip(controller: controller, opponent: true, compact: true),
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
                _Hand(
                  controller: controller,
                  cardWidth: 76,
                  scroll: true,
                ),
              ],
            ),
          ),
        ),
        _PlayerStrip(controller: controller, opponent: false, compact: true),
        _ActionRow(controller: controller, showHint: true),
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
                _PlayerPanel(controller: controller, opponent: true),
                const SizedBox(height: 10),
                _PlayerPanel(controller: controller, opponent: false),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _Header(controller: controller, compact: true),
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
                        _Hand(controller: controller, cardWidth: 88),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 300,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _PreviewPanel(controller: controller),
                const SizedBox(height: 10),
                _ScoreTable(state: controller.state),
                const SizedBox(height: 10),
                _ActionRow(controller: controller, vertical: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller, this.compact = false});

  final GameController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final opponent = controller.opponent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: GwentColors.gold.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: strings.menu,
            icon: const Icon(Icons.menu),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          ClipOval(
            child: Image.asset(
              factionInfo(opponent.faction).heroAsset,
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponent.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  strings.opponentSummary(
                    strings.factionName(opponent.faction),
                    strings.difficultyName(opponent.difficulty),
                  ),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GwentColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!compact)
            Text(
              strings.appTitle,
              style: const TextStyle(
                fontFamily: 'serif',
                color: GwentColors.goldBright,
                letterSpacing: 4,
                fontSize: 18,
              ),
            ),
          const SizedBox(width: 8),
          _RoundChip(state: controller.state),
        ],
      ),
    );
  }
}

class _RoundChip extends StatelessWidget {
  const _RoundChip({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GwentColors.gold.withValues(alpha: 0.45)),
        color: GwentColors.gold.withValues(alpha: 0.1),
      ),
      alignment: Alignment.center,
      child: Text(
        strings.roundOf(state.roundNumber.clamp(1, 3), 3),
        style: const TextStyle(
          color: GwentColors.goldBright,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Hand extends StatelessWidget {
  const _Hand({required this.controller, required this.cardWidth, this.scroll = false});

  final GameController controller;
  final double cardWidth;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final human = controller.human;
    final cards = human.hand;
    final children = [
      for (final card in cards)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GwentCard(
            definition: card.definition,
            strength: card.baseStrength,
            width: cardWidth,
            showName: false,
            selected: identical(controller.selectedCard, card),
            dim: !controller.engine.canPlayCard(human.index, card) &&
                controller.engine.isHumanTurn,
            onTap: () => controller.selectCard(card),
          ),
        ),
    ];
    if (scroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: children),
      );
    }
    return SizedBox(
      height: cardWidth * 6.35 / 4.45 + 4,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: children),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.controller,
    this.showHint = false,
    this.vertical = false,
  });

  final GameController controller;
  final bool showHint;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final humanTurn = controller.engine.isHumanTurn && !controller.isMulligan;
    final turnChip = TurnChip(
      label: humanTurn ? strings.yourTurn : strings.opponentTurn,
      active: humanTurn,
    );
    final passButton = FilledButton.tonalIcon(
      onPressed: humanTurn ? controller.pass : null,
      icon: const Icon(Icons.flag_outlined, size: 18),
      label: Text(vertical ? strings.passRound : strings.pass),
      style: FilledButton.styleFrom(
        backgroundColor: GwentColors.surfaceHigh,
        foregroundColor: GwentColors.parchment,
      ),
    );

    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: turnChip),
          const SizedBox(height: 8),
          passButton,
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          turnChip,
          const Spacer(),
          if (showHint)
            Flexible(
              child: Text(
                strings.tapCardDetails,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GwentColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(width: 8),
          passButton,
        ],
      ),
    );
  }
}

class _PlayerStrip extends StatelessWidget {
  const _PlayerStrip({
    required this.controller,
    required this.opponent,
    this.compact = false,
  });

  final GameController controller;
  final bool opponent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final player = opponent ? controller.opponent : controller.human;
    final total = Scoring.playerTotal(controller.state, player.index);
    final info = factionInfo(player.faction);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(
          top: opponent ? BorderSide.none : BorderSide(color: Colors.white12),
          bottom: opponent ? BorderSide(color: Colors.white12) : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Text(
            '$total',
            style: const TextStyle(
              color: GwentColors.goldBright,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.points.toUpperCase(),
                style: const TextStyle(
                  color: GwentColors.onSurfaceVariant,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              RoundGems(roundsWon: player.roundsWon),
            ],
          ),
          const Spacer(),
          _HandCount(count: player.hand.length),
          const SizedBox(width: 6),
          Pile(
            count: player.deck.length,
            backAsset: info.deckBackAsset,
            width: 28,
          ),
          const SizedBox(width: 6),
          Pile(
            count: player.graveyard.length,
            backAsset: info.deckBackAsset,
            width: 28,
            graveyard: true,
            icon: Icons.delete_outline,
          ),
        ],
      ),
    );
  }
}

class _HandCount extends StatelessWidget {
  const _HandCount({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GwentColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.style_outlined, size: 14, color: GwentColors.onSurfaceVariant),
          const SizedBox(width: 5),
          Text('$count', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({required this.controller, required this.opponent});

  final GameController controller;
  final bool opponent;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final player = opponent ? controller.opponent : controller.human;
    final total = Scoring.playerTotal(controller.state, player.index);
    final info = factionInfo(player.faction);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GwentColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GwentColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  info.heroAsset,
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opponent ? player.name : strings.you,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      strings.factionName(player.faction),
                      style: const TextStyle(
                        color: GwentColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (opponent)
                Chip(
                  label: Text(strings.difficultyName(player.difficulty)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  color: GwentColors.goldBright,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              RoundGems(roundsWon: player.roundsWon),
              const Spacer(),
              _HandCount(count: player.hand.length),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Pile(count: player.deck.length, backAsset: info.deckBackAsset),
              const SizedBox(width: 10),
              Pile(
                count: player.graveyard.length,
                backAsset: info.deckBackAsset,
                graveyard: true,
                icon: Icons.delete_outline,
              ),
              const Spacer(),
              if (!opponent)
                _LeaderButton(controller: controller)
              else
                GwentCard(
                  definition: player.leader,
                  width: 52,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderButton extends StatelessWidget {
  const _LeaderButton({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final player = controller.human;
    final available = player.leaderAvailable && controller.engine.isHumanTurn;
    return Column(
      children: [
        GwentCard(
          definition: player.leader,
          width: 52,
          dim: !player.leaderAvailable,
          onTap: available ? controller.activateLeader : null,
        ),
        const SizedBox(height: 3),
        Text(
          player.leaderAvailable ? strings.leaderReady : strings.leaderUsed,
          style: TextStyle(
            color: player.leaderAvailable
                ? GwentColors.goldBright
                : GwentColors.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final card = controller.selectedCard;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GwentColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GwentColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: card == null
          ? Align(
              alignment: Alignment.centerLeft,
              child: Text(
                strings.cardPreview.toUpperCase(),
                style: const TextStyle(
                  color: GwentColors.onSurfaceVariant,
                  fontSize: 12,
                  letterSpacing: 1.6,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GwentCard(definition: card.definition, width: 76),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _typeLine(strings, card.definition),
                            style: const TextStyle(
                              color: GwentColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  strings.cardDescription(card.definition),
                  style: const TextStyle(
                    color: GwentColors.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: controller.engine.isHumanTurn
                          ? () => controller.playSelected()
                          : null,
                      icon: const Icon(Icons.double_arrow_rounded, size: 18),
                      label: Text(strings.playCard),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: controller.clearSelection,
                      child: Text(strings.cancel),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  String _typeLine(dynamic strings, CardDefinition card) {
    if (card.isLeader) return strings.cardTypeLeader;
    if (card.isWeather) return strings.cardTypeWeather;
    if (card.isSpecial) return strings.cardTypeSpecial;
    final row = card.row == CardRow.agile ? CardRow.close : card.row;
    final hero = card.isHero ? ' · ${strings.tagHero}' : '';
    return '${strings.rowName(row)}$hero';
  }
}

class _ScoreTable extends StatelessWidget {
  const _ScoreTable({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Table(
      columnWidths: const {0: FlexColumnWidth(1.4)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            for (final label in ['R1', 'R2', 'R3'])
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: GwentColors.onSurfaceVariant,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
          ],
        ),
        for (final player in state.players)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  player.isHuman ? strings.you : player.name,
                  style: const TextStyle(color: GwentColors.onSurfaceVariant),
                ),
              ),
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    _cell(player.index, i),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _color(player.index, i),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  String _cell(int player, int roundIndex) {
    if (roundIndex < state.roundHistory.length) {
      return '${state.roundHistory[roundIndex].scores[player]}';
    }
    if (roundIndex == state.roundNumber - 1 && state.phase != GamePhase.gameOver) {
      return '${Scoring.playerTotal(state, player)}';
    }
    return '—';
  }

  Color _color(int player, int roundIndex) {
    if (roundIndex < state.roundHistory.length) {
      final winner = state.roundHistory[roundIndex].winner;
      if (winner == null) return GwentColors.onSurface;
      return winner == player ? GwentColors.goldBright : GwentColors.error;
    }
    if (roundIndex == state.roundNumber - 1) return GwentColors.onSurface;
    return GwentColors.outline;
  }
}

// -----------------------------------------------------------------------------
// Overlays
// -----------------------------------------------------------------------------

class _MulliganOverlay extends StatelessWidget {
  const _MulliganOverlay({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.88),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                strings.mulliganTitle(controller.redrawsLeft + controller.redrawPicks.length),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${strings.cardsInHand}: ${controller.human.hand.length}',
                style: const TextStyle(color: GwentColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final card in controller.human.hand)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GwentCard(
                            definition: card.definition,
                            strength: card.baseStrength,
                            width: 96,
                            selected: controller.redrawPicks.contains(card),
                            onTap: () => controller.toggleRedraw(card),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton.icon(
                  onPressed: controller.confirmMulligan,
                  icon: const Icon(Icons.check),
                  label: Text(strings.mulliganConfirm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceOverlay extends StatelessWidget {
  const _ChoiceOverlay({required this.controller, required this.choice});

  final GameController controller;
  final PendingChoice choice;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GwentColors.surfaceHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: GwentColors.gold.withValues(alpha: 0.3)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    switch (choice) {
                      RowChoice() => strings.selectRowHint,
                      TargetChoice() => strings.selectTargetHint,
                    },
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: controller.clearSelection,
                    child: Text(strings.cancel),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              switch (choice) {
                RowChoice(:final rows) => Wrap(
                  spacing: 8,
                  children: [
                    for (final row in rows)
                      FilledButton.tonal(
                        onPressed: () =>
                            controller.playSelected(row: row),
                        child: Text(strings.rowName(row)),
                      ),
                  ],
                ),
                TargetChoice(:final targets) => SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: targets.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final target = targets[index];
                      return GwentCard(
                        definition: target.definition,
                        strength: target.baseStrength,
                        width: 78,
                        onTap: () => controller.playSelected(target: target),
                      );
                    },
                  ),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}
