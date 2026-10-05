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

/// Directed broadcast address of [address] on a /[prefixLength] subnet, such as
/// `192.168.1.255`; null when the address is not a usable IPv4 subnet.
String? directedBroadcast(InternetAddress address, int prefixLength) {
  final raw = address.rawAddress;
  if (raw.length != 4 || prefixLength <= 0 || prefixLength >= 32) return null;
  final ip = raw[0] << 24 | raw[1] << 16 | raw[2] << 8 | raw[3];
  final mask = (0xFFFFFFFF << (32 - prefixLength)) & 0xFFFFFFFF;
  final target = (ip & mask) | (~mask & 0xFFFFFFFF);
  return '${target >> 24 & 0xFF}.${target >> 16 & 0xFF}'
      '.${target >> 8 & 0xFF}.${target & 0xFF}';
}

/// Virtual interfaces whose subnet would only add an address a guest cannot
/// reach: containers, VMs, VPN tunnels and the like.
const Set<String> _virtualInterfacePrefixes = {
  'docker', 'veth', 'br-', 'virbr', 'vmnet', 'vboxnet', 'tun', 'tap', 'wg',
  'zt', 'tailscale', 'utun',
};

/// Whether [name] belongs to a virtual interface rather than a real network.
bool isVirtualInterface(String name) {
  final lower = name.toLowerCase();
  return _virtualInterfacePrefixes.any(lower.startsWith);
}

/// Subnet broadcasts of every IPv4 interface on this device.
///
/// Over Wi-Fi the limited broadcast `255.255.255.255` is dropped by some access
/// points while the directed one gets through (and vice versa), so the announcer
/// sends to both. Best-effort: a failure just leaves the limited broadcast.
Future<List<String>> localBroadcastTargets() async {
  final targets = <String>[];
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final interface in interfaces) {
      if (isVirtualInterface(interface.name)) continue;
      for (final address in interface.addresses) {
        final target = directedBroadcast(address, address.prefixLength);
        if (target != null && !targets.contains(target)) targets.add(target);
      }
    }
  } on SocketException {
    // Nothing to add.
  }
  return targets;
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
    this.targets = localBroadcastTargets,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  /// UDP port both sides agree on.
  static const int defaultPort = 41235;

  final String id;
  final String name;
  final int matchPort;
  final String target;

  /// Extra destinations resolved when [start] runs, normally the subnet
  /// broadcasts of the device's own interfaces.
  final Future<List<String>> Function() targets;
  final int port;
  final Duration interval;

  List<String> _extraTargets = const [];

  RawDatagramSocket? _socket;
  Timer? _timer;

  Future<void> start() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    _socket = socket;
    _extraTargets = await targets();
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
    for (final destination in {target, ..._extraTargets}) {
      socket.send(payload, InternetAddress(destination), port);
    }
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

    // A host that announces on several interfaces is one host: keep the first
    // address seen for it instead of listing it once per datagram.
    if (!_seen.add(id)) return;
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
