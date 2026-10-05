import '../rules/game_command.dart';

/// Message type tags used by the session layer.
abstract final class SessionMessage {
  static const hello = 'hello';
  static const welcome = 'welcome';
  static const deck = 'deck';
  static const start = 'start';
  static const command = 'command';
  static const rejected = 'rejected';
  static const view = 'view';
  static const reject = 'reject';
  static const bye = 'bye';
}

/// Reasons a session can end before or during a match.
abstract final class SessionFailure {
  static const versions = 'versions';
  static const deck = 'deck';
  static const protocol = 'protocol';
  static const closed = 'closed';
}

/// Events a session raises for the presentation layer.
sealed class SessionEvent {
  const SessionEvent();
}

/// The handshake completed and this client's seat is known.
class SessionReady extends SessionEvent {
  const SessionReady(this.seat);

  final int seat;
}

/// The host started the match; a view follows.
class SessionStarted extends SessionEvent {
  const SessionStarted();
}

/// A fresh projection arrived (client side).
class SessionViewUpdated extends SessionEvent {
  const SessionViewUpdated(this.view);

  final Map<String, Object?> view;
}

/// The host refused a command.
class SessionCommandRejected extends SessionEvent {
  const SessionCommandRejected(this.reason);

  final CommandRejection reason;
}

/// The peer went away. The match can continue once it reconnects.
class SessionPeerLost extends SessionEvent {
  const SessionPeerLost();
}

/// The session ended: version mismatch, malformed payload or disconnect.
class SessionFailed extends SessionEvent {
  const SessionFailed(this.code);

  final String code;
}
