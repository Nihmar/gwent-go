import 'dart:async';

/// Message transport between two match peers.
///
/// The session layer only needs a reliable, ordered stream of JSON-friendly
/// maps, so LAN sockets, an in-memory pipe or a future Bluetooth link can all
/// implement it without touching the rules.
abstract interface class MatchTransport {
  /// Messages arriving from the peer.
  Stream<Map<String, Object?>> get incoming;

  /// Sends [message] to the peer.
  void send(Map<String, Object?> message);

  /// Closes the local end. The peer sees the stream complete.
  Future<void> close();
}

/// A connected pair of in-memory transports, used by tests and by hotseat play.
(MatchTransport, MatchTransport) loopbackTransportPair() {
  final left = StreamController<Map<String, Object?>>();
  final right = StreamController<Map<String, Object?>>();
  return (
    _Pipe(incoming: left.stream, outgoing: right),
    _Pipe(incoming: right.stream, outgoing: left),
  );
}

class _Pipe implements MatchTransport {
  _Pipe({required this.incoming, required this.outgoing});

  @override
  final Stream<Map<String, Object?>> incoming;

  final StreamController<Map<String, Object?>> outgoing;

  @override
  void send(Map<String, Object?> message) {
    if (outgoing.isClosed) return;
    outgoing.add(message);
  }

  @override
  Future<void> close() async {
    if (!outgoing.isClosed) await outgoing.close();
  }
}
