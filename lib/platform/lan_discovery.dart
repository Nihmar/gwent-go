import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A hosted match seen on the local network.
class DiscoveredHost {
  const DiscoveredHost({
    required this.id,
    required this.name,
    required this.address,
    required this.matchPort,
  });

  /// Token that identifies the host process, so a browser can ignore itself.
  final String id;
  final String name;

  /// Address to connect to (the datagram source).
  final String address;

  /// Port the host's match socket listens on.
  final int matchPort;

  @override
  String toString() => 'DiscoveredHost($name, $address:$matchPort)';
}

/// Announces a hosted match to the local network until [stop] is called.
///
/// The payload is a small JSON datagram; a peer running [LanBrowser] turns it
/// into a [DiscoveredHost]. Discovery is best-effort: when the network blocks
/// broadcasts the lobby still offers a manual address entry.
class LanAnnouncer {
  LanAnnouncer({
    required this.name,
    required this.matchPort,
    this.target = '255.255.255.255',
    this.port = defaultPort,
    this.interval = const Duration(seconds: 2),
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  /// UDP port both sides agree on.
  static const int defaultPort = 41235;

  final String id;
  final String name;
  final int matchPort;
  final String target;
  final int port;
  final Duration interval;

  RawDatagramSocket? _socket;
  Timer? _timer;

  Future<void> start() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    _socket = socket;
    _send();
    _timer = Timer.periodic(interval, (_) => _send());
  }

  void _send() {
    final socket = _socket;
    if (socket == null) return;
    final payload = utf8.encode(
      jsonEncode({
        'type': LanBrowser.messageType,
        'id': id,
        'name': name,
        'port': matchPort,
      }),
    );
    socket.send(payload, InternetAddress(target), port);
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _socket?.close();
    _socket = null;
  }
}

/// Listens for [LanAnnouncer]s on the local network.
class LanBrowser {
  LanBrowser({this.port = LanAnnouncer.defaultPort, this.ignoreId});

  /// Tag every announcement carries, so unrelated datagrams are ignored.
  static const String messageType = 'gwent-go.lan';

  final int port;

  /// Id to ignore, normally this device's own announcer.
  final String? ignoreId;

  RawDatagramSocket? _socket;
  final StreamController<DiscoveredHost> _hosts =
      StreamController<DiscoveredHost>.broadcast();
  final Set<String> _seen = {};

  /// Hosts as they are discovered; each host is emitted once.
  Stream<DiscoveredHost> get hosts => _hosts.stream;

  /// The bound port, known after [start] (useful when binding port 0).
  int get boundPort => _socket?.port ?? port;

  Future<void> start() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    socket.broadcastEnabled = true;
    _socket = socket;
    socket.listen(_onEvent);
  }

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket?.receive();
    if (datagram == null) return;
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(datagram.data));
    } on FormatException {
      return;
    }
    if (decoded is! Map) return;
    if (decoded['type'] != messageType) return;
    final id = decoded['id'];
    if (id is! String || id == ignoreId) return;

    final address = datagram.address.address;
    final matchPort = decoded['port'];
    if (matchPort is! int) return;

    final key = '$id|$address|$matchPort';
    if (!_seen.add(key)) return;
    _hosts.add(
      DiscoveredHost(
        id: id,
        name: decoded['name'] as String? ?? address,
        address: address,
        matchPort: matchPort,
      ),
    );
  }

  Future<void> close() async {
    _socket?.close();
    _socket = null;
    await _hosts.close();
  }
}
