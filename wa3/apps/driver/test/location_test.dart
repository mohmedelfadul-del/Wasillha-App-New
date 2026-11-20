import 'package:flutter_test/flutter_test.dart';
import 'package:wasilha_driver/features/location/application/location_service.dart';
import 'package:wasilha_driver/features/location/domain/cadence_policy.dart';
import 'package:wasilha_driver/features/location/domain/location_port.dart';

import 'fakes.dart';

void main() {
  final t0 = DateTime(2026, 11, 20, 12);
  Fix fix({double lat = 15.5, double lng = 32.5, double? speed, required DateTime at}) => Fix(lat: lat, lng: lng, speed: speed, at: at);
  const p = CadencePolicy();

  group('CadencePolicy', () {
    test('first fix is always sent', () {
      expect(p.shouldSend(now: t0, fix: fix(at: t0)), isTrue);
    });

    test('moving (speed): every 5 s', () {
      final last = fix(at: t0);
      final next = fix(speed: 8, at: t0.add(const Duration(seconds: 4)));
      expect(p.shouldSend(now: t0.add(const Duration(seconds: 4)), fix: next, lastSent: last, lastSentAt: t0), isFalse);
      expect(p.shouldSend(now: t0.add(const Duration(seconds: 5)), fix: next, lastSent: last, lastSentAt: t0), isTrue);
    });

    test('moving (displacement ≥ 10 m without a speed reading): every 5 s', () {
      final last = fix(at: t0);
      final moved = fix(lat: 15.5002, at: t0.add(const Duration(seconds: 5))); // ≈ 22 m north
      expect(p.isMoving(moved, lastSent: last), isTrue);
      expect(p.shouldSend(now: t0.add(const Duration(seconds: 5)), fix: moved, lastSent: last, lastSentAt: t0), isTrue);
    });

    test('stationary: heartbeat every 15 s', () {
      final last = fix(at: t0);
      final still = fix(speed: 0.2, at: t0.add(const Duration(seconds: 6)));
      expect(p.shouldSend(now: t0.add(const Duration(seconds: 14)), fix: still, lastSent: last, lastSentAt: t0), isFalse);
      expect(p.shouldSend(now: t0.add(const Duration(seconds: 15)), fix: still, lastSent: last, lastSentAt: t0), isTrue);
    });

    test('re-sending the same reading is a heartbeat even if it reported speed', () {
      final last = fix(speed: 12, at: t0);
      expect(p.isMoving(last, lastSent: last), isFalse);
      expect(p.shouldSend(now: t0.add(const Duration(seconds: 6)), fix: last, lastSent: last, lastSentAt: t0), isFalse);
      expect(p.shouldSend(now: t0.add(const Duration(seconds: 15)), fix: last, lastSent: last, lastSentAt: t0), isTrue);
    });

    test('distance helper', () {
      expect(distanceMeters(fix(at: t0), fix(lat: 15.501, at: t0)), closeTo(111, 2));
    });
  });

  group('LocationService', () {
    testWidgets('writes on cadence, heartbeats when quiet, stops when told', (t) async {
      var now = t0;
      final f = Fakes();
      final svc = LocationService(source: f.locationSource, sink: f.sink, clock: () => now);
      Future<void> advance(int seconds) async {
        for (var i = 0; i < seconds; i++) {
          now = now.add(const Duration(seconds: 1));
          await t.pump(const Duration(seconds: 1));
        }
      }

      svc.start('d1');
      f.locationSource.fixesCtl.add(fix(speed: 0, at: now));
      await t.pump();
      expect(f.sink.writes.length, 1);
      expect(await svc.waitForFirstWrite(const Duration(seconds: 1)), isTrue);

      await advance(14); // stationary, GPS quiet
      expect(f.sink.writes.length, 1);
      await advance(1);
      expect(f.sink.writes.length, 2, reason: 'heartbeat at 15 s');

      f.locationSource.fixesCtl.add(fix(lat: 15.51, speed: 9, at: now));
      await advance(4);
      expect(f.sink.writes.length, 2);
      await advance(1);
      expect(f.sink.writes.length, 3, reason: 'moving: 5 s');
      expect(f.sink.writes.last.uid, 'd1');

      svc.stop();
      await advance(30);
      expect(f.sink.writes.length, 3);
      expect(svc.running, isFalse);
      svc.dispose();
    });

    testWidgets('denied permission is reported, not hidden', (t) async {
      final f = Fakes();
      f.locationSource.access = LocationAccess.deniedForever;
      final svc = LocationService(source: f.locationSource, sink: f.sink);
      expect(await svc.requestAccess(), LocationAccess.deniedForever);
      expect(svc.access, LocationAccess.deniedForever);
      svc.dispose();
    });
  });
}
