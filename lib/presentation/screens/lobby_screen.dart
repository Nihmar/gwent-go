import 'package:flutter/material.dart';

import '../../core/models/player.dart';
import '../controllers/game_controller.dart';
import '../controllers/lobby_controller.dart';
import '../controllers/settings_controller.dart';
import '../localization.dart';
import '../theme/gwent_colors.dart';
import '../widgets/board_background.dart';
import 'game_screen.dart';

/// Hosts or joins a LAN match.
///
/// The screen only drives [LobbyController]; discovery, the TCP transport and
/// the sessions live there.
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.settings, this.lobby});

  final SettingsController settings;

  /// Injected in tests; a real one is created by default.
  final LobbyController? lobby;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late final LobbyController _lobby;
  late final bool _ownsLobby;
  final TextEditingController _address = TextEditingController();
  bool _openedMatch = false;

  @override
  void initState() {
    super.initState();
    _ownsLobby = widget.lobby == null;
    _lobby = widget.lobby ?? LobbyController();
    _lobby.addListener(_onLobby);
  }

  @override
  void dispose() {
    _lobby.removeListener(_onLobby);
    if (_ownsLobby) _lobby.dispose();
    _address.dispose();
    super.dispose();
  }

  DeckDefinition get _deck =>
      widget.settings.deckFor(widget.settings.settings.faction);

  void _onLobby() {
    if (!mounted) return;
    setState(() {});
    if (_lobby.isReady) _openMatch();
  }

  void _openMatch() {
    if (_openedMatch) return;
    final host = _lobby.hostSession;
    final client = _lobby.clientSession;
    final controller = host != null
        ? GameController.host(host)
        : client != null
        ? GameController.remote(session: client, localSeat: client.seat ?? 1)
        : null;
    if (controller == null) return;
    _openedMatch = true;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => GameScreen(controller: controller)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(strings.lanMatch)),
      body: BoardBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _statusCard(context),
              const SizedBox(height: 20),
              _hostSection(context),
              const Divider(height: 40),
              _joinSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard(BuildContext context) {
    final strings = context.strings;
    if (_lobby.status == LobbyStatus.idle ||
        _lobby.status == LobbyStatus.ready) {
      return const SizedBox.shrink();
    }
    final (text, progress) = switch (_lobby.status) {
      LobbyStatus.waitingForGuest => (strings.hosting, true),
      LobbyStatus.browsing => (strings.searchingHosts, true),
      LobbyStatus.connecting => (strings.joinMatch, true),
      LobbyStatus.failed => (strings.lobbyFailed, false),
      LobbyStatus.idle || LobbyStatus.ready => ('', false),
    };
    return Row(
      children: [
        if (progress) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
        ] else
          const Icon(Icons.error_outline, color: GwentColors.error),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: _lobby.status == LobbyStatus.failed
                  ? GwentColors.error
                  : GwentColors.onSurface,
            ),
          ),
        ),
        if (_lobby.failure != null)
          Text(
            _lobby.failure!,
            style: const TextStyle(
              color: GwentColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        if (progress)
          TextButton(
            onPressed: _lobby.cancel,
            child: Text(context.strings.cancel),
          ),
      ],
    );
  }

  Widget _hostSection(BuildContext context) {
    final strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(strings.hostMatch, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          '${strings.factionName(_deck.faction)} · ${_deck.name}',
          style: const TextStyle(
            color: GwentColors.onSurfaceVariant,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _lobby.status == LobbyStatus.idle
              ? () => _lobby.hostMatch(_deck)
              : null,
          icon: const Icon(Icons.wifi_tethering),
          label: Text(strings.hostMatch),
        ),
        if (_lobby.role == LobbyRole.hosting) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _lobby.cancel,
            child: Text(strings.cancelHosting),
          ),
        ],
      ],
    );
  }

  Widget _joinSection(BuildContext context) {
    final strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(strings.joinMatch, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: _lobby.status == LobbyStatus.idle
              ? () => _lobby.browse()
              : null,
          icon: const Icon(Icons.search),
          label: Text(strings.searchingHosts),
        ),
        const SizedBox(height: 12),
        if (_lobby.hosts.isEmpty)
          Text(
            strings.noHostsFound,
            style: const TextStyle(
              color: GwentColors.onSurfaceVariant,
              fontSize: 12.5,
            ),
          )
        else
          for (final host in _lobby.hosts)
            ListTile(
              dense: true,
              leading: const Icon(Icons.computer),
              title: Text(host.name),
              subtitle: Text('${host.address}:${host.matchPort}'),
              onTap: () => _lobby.joinMatch(host, _deck),
            ),
        const Divider(height: 28),
        TextField(
          controller: _address,
          decoration: InputDecoration(
            labelText: strings.joinAddress,
            filled: true,
            fillColor: GwentColors.surfaceHigh,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () {
            final address = _address.text.trim();
            if (address.isEmpty) return;
            _lobby.joinAddress(address, _deck);
          },
          child: Text(strings.joinMatch),
        ),
      ],
    );
  }
}
