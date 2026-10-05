import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/session/match_transport.dart';

/// [MatchTransport] over TCP with newline-delimited JSON messages.
///
/// TCP already guarantees ordering and delivery, so the session layer only
/// needs one JSON object per line. The same class serves both ends: [connect]
/// for the guest and [accept] for the host accepting one guest.
///
/// This is platform code; the core only knows [MatchTransport].
class TcpMatchTransport implements MatchTransport {
  TcpMatchTransport._(this._socket) {
    _socket.setOption(SocketOption.tcpNoDelay, true);
    // Write errors on a socket whose peer vanished surface on `done`; they are
    // expected when a peer disappears and must not become uncaught errors.
    unawaited(_socket.done.then((_) {}, onError: (Object _) {}));
    _subscription = _socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          _onLine,
          onDone: _closeIncoming,
          onError: (_) => _closeIncoming(),
          cancelOnError: true,
        );
  }

  /// Default port the host listens on when none is given.
  static const int defaultPort = 41234;

  final Socket _socket;
  late final StreamSubscription<String> _subscription;
  bool _closed = false;
  final StreamController<Map<String, Object?>> _incoming =
      StreamController<Map<String, Object?>>();

  @override
  Stream<Map<String, Object?>> get incoming => _incoming.stream;

  /// Connects to a host.
  static Future<TcpMatchTransport> connect(
    String host, {
    int port = defaultPort,
  }) async => TcpMatchTransport._(await Socket.connect(host, port));

  /// Waits for the first guest on a bound [server] and closes it afterwards,
  /// since a match is one against one.
  static Future<TcpMatchTransport> accept(ServerSocket server) async {
    try {
      return TcpMatchTransport._(await server.first);
    } finally {
      await server.close();
    }
  }

  /// Binds [port] so a guest can connect; returns the listening socket.
  static Future<ServerSocket> listen({int port = defaultPort}) =>
      ServerSocket.bind(InternetAddress.anyIPv4, port);

  @override
  void send(Map<String, Object?> message) {
    if (_closed) return;
    try {
      _socket.write('${jsonEncode(message)}\n');
    } on SocketException {
      // The peer went away; the incoming stream will complete and the session
      // reports the disconnect.
    }
  }

  void _onLine(String line) {
    if (line.trim().isEmpty) return;
    final decoded = jsonDecode(line);
    if (decoded is Map) _incoming.add(decoded.cast<String, Object?>());
  }

  void _closeIncoming() {
    if (!_incoming.isClosed) _incoming.close();
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _subscription.cancel();
    _socket.destroy();
    _closeIncoming();
  }
}
