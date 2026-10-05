# Future transports: Wi-Fi Direct and Bluetooth

Investigation note for phase 8 of the [multiplayer plan](multiplayer.md). No
implementation is scheduled; this records how each transport would map onto the
existing abstractions, what it costs and which risks have to be answered first.

Everything below sits behind two seams that already exist:

- `MatchTransport` (`lib/core/session/match_transport.dart`) — a stream of
  JSON-friendly maps plus `send`/`close`. The sessions, the lobby and the
  protocol do not know what carries the bytes.
- `LobbyController` — owns discovery, dialling and teardown, and only exposes a
  status plus the ready session.

A new transport therefore means: one `MatchTransport` implementation in
`lib/platform/`, one discovery strategy (or manual entry), and a lobby option to
choose it.

## Current baseline: LAN over TCP

`TcpMatchTransport` plus `LanAnnouncer`/`LanBrowser` (UDP) already cover the
same-network case, and are the recommended default: no pairing, both devices
keep their normal network connection, and the host's TCP server is reachable by
address when discovery is blocked.

Over Wi-Fi the announcements go to the subnet broadcast of every physical
interface *and* to `255.255.255.255`, because access points differ in which of
the two they forward; virtual interfaces (containers, VMs, VPN tunnels) are
skipped, and the browser lists a host once even when several datagrams reach it.

The message set is small: commands are a few hundred bytes at most, and a
projection is the whole visible board — currently a few kilobytes of JSON, sent
after every action. Any transport must handle that comfortably.

## Wi-Fi Direct (Android)

**What it gives**: a direct Wi-Fi link between two devices without a router, so
two phones can play without an access point. Discovery is built in (the
platform advertises and finds peers).

**Mapping**:

- Discovery replaces `LanBrowser`: the platform reports reachable peers with a
  display name, which maps onto the existing `DiscoveredHost` shape.
- The socket layer replaces `TcpMatchTransport`: after the group is formed, the
  group owner runs the same TCP server and the client connects to the group
  owner's address. In other words, only discovery is genuinely different; the
  messaging stays TCP.
- `LobbyController` gains a transport/discovery strategy instead of hard-coding
  `TcpMatchTransport`/`LanBrowser`; the status machine (`waitingForGuest`,
  `browsing`, `connecting`, `ready`, `failed`) already fits.

**Costs and risks**:

- Platform-only: Android. iOS has *Multipeer Connectivity* with a similar shape
  but a different API, so the abstraction must stay behind `lib/platform/`.
- Permissions and radios: `NEARBY_WIFI_DEVICES` (Android 13+),
  `ACCESS_FINE_LOCATION` (older), and the user must accept the system dialog.
- The group owner is negotiated by the platform, so the host/guest roles must be
  decided after the group forms rather than before.
- Losing the group tears the link down; reconnection (phase 7) has to re-form it
  first, which is slower than re-dialling a LAN socket.

**Verdict**: worth doing as the first alternative transport, because discovery is
the only new concept; the session layer needs no change.

## Bluetooth

**What it gives**: the only option when there is no shared network at all, at
the cost of a pairing flow and a much slower link.

**Mapping**:

- RFCOMM (classic) gives a stream socket, so a line-delimited JSON transport can
  mirror `TcpMatchTransport` almost line for line.
- BLE is the wrong shape for this: GATT is request/response with small
  characteristics and no natural stream. It would need chunking and
  reassembly — a new protocol on top of the session layer, not a transport.
- Pairing replaces discovery: peers exchange addresses out of band (QR code or
  the system pairing UI), and the lobby needs a manual "connect to paired
  device" step rather than a scan list.

**Costs and risks**:

- Throughput: RFCOMM is roughly an order of magnitude slower than Wi-Fi. A full
  projection after every action is acceptable, but it makes per-action deltas
  more attractive (already noted as a possible optimisation for LAN).
- Platform plugins differ per OS and are less maintained than socket APIs, on
  Linux and Windows in particular.
- Pairing is a modal, error-prone flow; a failed pairing currently has no good
  in-game recovery story.
- Android permissions (`BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`) and Linux/Windows
  differences make this the least portable option.

**Verdict**: keep as a last resort. If it is implemented, prefer RFCOMM over
BLE, keep it behind the same `MatchTransport`, and treat the pairing step as a
lobby concern.

## What would have to be added regardless

- **Transport selection in the lobby**: a small enum (LAN, Wi-Fi Direct,
  Bluetooth) that picks a `MatchTransport`/discovery pair; the status machine
  and screens stay as they are.
- **Manual fallback everywhere**: discovery can be blocked on managed networks,
  so the address field must stay, and Wi-Fi Direct/Bluetooth need an equivalent
  path (a "connect to the last peer" action).
- **Projection deltas**: to keep slow links usable, sending changed rows and
  cards instead of the whole projection would help every transport.
- **Reconnection per transport**: phase 7 resyncs a link; Wi-Fi Direct has to
  re-form the group first, and Bluetooth may need re-pairing.

## Recommendation

1. Keep **LAN as the default** and finish its UX (reconnection banner and
   timeout, tracked in #44).
2. Add **Wi-Fi Direct on Android** first if a transport beyond LAN is wanted: it
   reuses the TCP messaging entirely and only changes discovery.
3. Treat **Bluetooth (RFCOMM)** as a later, best-effort addition, and do not
   attempt BLE without a chunking protocol and a reason for it.
