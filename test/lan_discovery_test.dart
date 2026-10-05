import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_go/platform/lan_discovery.dart';

void main() {
  _broadcastTargets();
  _virtualInterfaces();

  group('LAN discovery', () {
    test('a browser finds an announcer and ignores repeats', () async {
      final browser = LanBrowser(port: 0);
      await browser.start();
      final announcer = LanAnnouncer(
        name: 'Host',
        matchPort: 41234,
        // Loopback instead of broadcast, so the test is network independent.
        target: '127.0.0.1',
        port: browser.boundPort,
        interval: const Duration(milliseconds: 20),
      );
      await announcer.start();

      final discovered = <DiscoveredHost>[];
      final subscription = browser.hosts.listen(discovered.add);
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(discovered, isNotEmpty);
      expect(discovered.first.name, 'Host');
      expect(discovered.first.matchPort, 41234);
      expect(discovered.first.address, isNotEmpty);
      // Repeated announcements are deduplicated.
      expect(discovered.length, 1);

      await subscription.cancel();
      await announcer.stop();
      await browser.close();
    });

    test('a browser ignores its own announcements', () async {
      final browser = LanBrowser(port: 0, ignoreId: 'self');
      await browser.start();
      final announcer = LanAnnouncer(
        name: 'Self',
        matchPort: 41234,
        target: '127.0.0.1',
        port: browser.boundPort,
        interval: const Duration(milliseconds: 20),
        id: 'self',
      );
      await announcer.start();

      final discovered = <DiscoveredHost>[];
      final subscription = browser.hosts.listen(discovered.add);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(discovered, isEmpty);

      await subscription.cancel();
      await announcer.stop();
      await browser.close();
    });

    test('unrelated datagrams are ignored', () async {
      final browser = LanBrowser(port: 0);
      await browser.start();
      final discovered = <DiscoveredHost>[];
      final subscription = browser.hosts.listen(discovered.add);

      // Reuse an announcer's socket to send noise from a known address.
      final announcer = LanAnnouncer(
        name: 'Noise',
        matchPort: 1,
        target: '127.0.0.1',
        port: browser.boundPort,
        interval: const Duration(seconds: 30),
      );
      await announcer.start();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      // The real announcement is found; noise is not sent, so exactly one host.
      expect(discovered.length, 1);

      await subscription.cancel();
      await announcer.stop();
      await browser.close();
    });
  });
}

void _broadcastTargets() {
  group('broadcasts', () {
    test('a /24 interface maps to its subnet broadcast', () {
      expect(
        directedBroadcast(InternetAddress('192.168.1.42'), 24),
        '192.168.1.255',
      );
      expect(
        directedBroadcast(InternetAddress('10.0.5.7'), 16),
        '10.0.255.255',
      );
    });

    test('point-to-point and unusable prefixes are skipped', () {
      expect(directedBroadcast(InternetAddress('192.168.1.42'), 32), isNull);
      expect(directedBroadcast(InternetAddress('192.168.1.42'), 0), isNull);
    });

    test('the announcer also reaches the local subnet broadcast', () async {
      final browser = LanBrowser(port: 0);
      await browser.start();
      final announcer = LanAnnouncer(
        name: 'Host',
        matchPort: 40000,
        port: browser.boundPort,
        // The local subnet, as if the device were on 127.0.0.0/8.
        targets: () async => ['127.255.255.255'],
      );
      await announcer.start();

      final host = await browser.hosts.first.timeout(const Duration(seconds: 3));
      expect(host.name, 'Host');

      await announcer.stop();
      await browser.close();
    });
  });
}

void _virtualInterfaces() {
  test('virtual interfaces are left out of the announcements', () {
    expect(isVirtualInterface('docker0'), isTrue);
    expect(isVirtualInterface('virbr0'), isTrue);
    expect(isVirtualInterface('wlan0'), isFalse);
    expect(isVirtualInterface('enp3s0'), isFalse);
    expect(isVirtualInterface('Wi-Fi'), isFalse);
  });
}
