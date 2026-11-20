import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_driver/features/auth/domain/phone_number.dart';
import 'package:wasilha_driver/features/notifications/domain/notification_feed.dart';

import 'fakes.dart';

void main() {
  test('phone numbers default to +249', () {
    expect(normalizePhone('0912345678'), '+249912345678');
    expect(normalizePhone('912 345 678'), '+249912345678');
    expect(normalizePhone('249912345678'), '+249912345678');
    expect(normalizePhone('+249 91 234 5678'), '+249912345678');
    expect(normalizePhone('00201001234567'), '+201001234567');
    expect(normalizePhone('12345'), isNull);
    expect(normalizePhone('+24991234'), isNull);
    expect(normalizePhone('abc'), isNull);
  });

  test('notices: document decisions and trip outcomes, newest first', () {
    final rejected = ReviewDocument.fromJson('drivers/d1/documents/national_id', {
      'type': 'national_id', 'status': 'rejected', 'reason': 'Blurry', 'driverId': 'd1', 'submittedAt': 1, 'decidedAt': 3000,
    });
    final pending = ReviewDocument.fromJson('drivers/d1/documents/driver_photo', {'type': 'driver_photo', 'status': 'pending', 'driverId': 'd1', 'submittedAt': 1});
    final done = trip(state: TripState.completed, extra: {'timestamps': {'completed': 5000}, 'riderRating': {'stars': 5}});
    final cancelled = trip(state: TripState.cancelled, extra: {'cancellation': {'actor': 'rider', 'reason': 'change_of_plans', 'at': 4000}});
    final n = buildNotices(documents: [rejected, pending], trips: [done, cancelled]);
    expect(n.map((e) => e.kind), [NoticeKind.riderRated, NoticeKind.tripCompleted, NoticeKind.tripCancelled, NoticeKind.documentRejected]);
  });
}
