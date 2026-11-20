import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';

/// Fails if the Dart contract drifts from the server's contract.ts.
void main() {
  final ts = File('../../backend/functions/src/domain/contract.ts').readAsStringSync();

  List<String> constArray(String name) {
    final m = RegExp('export const $name = \\[([^\\]]*)\\]', multiLine: true).firstMatch(ts);
    expect(m, isNotNull, reason: '$name not found in contract.ts');
    return RegExp(r'"([^"]+)"').allMatches(m!.group(1)!).map((x) => x.group(1)!).toList();
  }

  test('trip states match', () => expect(TripState.values.map((e) => e.name).toList(), constArray('TRIP_STATES')));
  test('categories match', () => expect(Category.values.map((e) => e.name).toList(), constArray('CATEGORIES')));
  test('document types match', () => expect(DocumentType.values.map((e) => e.name).toList(), constArray('DOCUMENT_TYPES')));
  test('review statuses match', () => expect(ReviewStatus.values.map((e) => e.name).toList(), constArray('REVIEW_STATUSES')));
  test('driver statuses match', () => expect(DriverStatus.values.map((e) => e.name).toList(), constArray('DRIVER_STATUSES')));
  test('offer statuses match', () => expect(OfferStatus.values.map((e) => e.name).toList(), constArray('OFFER_STATUSES')));
  test('ledger kinds match', () => expect(LedgerKind.values.map((e) => e.name).toList(), constArray('LEDGER_KINDS')));
  test('staff roles match', () => expect(StaffRole.values.map((e) => e.name).toList(), constArray('STAFF_ROLES')));
  test('error codes match', () => expect(errorCodes, constArray('ERROR_CODES')));

  test('cancel reasons match', () {
    for (final actor in ['rider', 'driver', 'ops', 'system']) {
      final m = RegExp('$actor: \\[([^\\]]*)\\]').firstMatch(ts)!;
      final server = RegExp(r'"([^"]+)"').allMatches(m.group(1)!).map((x) => x.group(1)!).toList();
      expect(cancelReasons[actor], server, reason: actor);
    }
  });

  test('tunables match', () {
    int n(String k) => int.parse(RegExp('$k: ([0-9 *]+),').firstMatch(ts)!.group(1)!.split('*').map((e) => int.parse(e.trim())).reduce((a, b) => a * b).toString());
    expect(Tunables.offerTtlSeconds, n('offerTtlSeconds'));
    expect(Tunables.requestTtlSeconds, n('requestTtlSeconds'));
    expect(Tunables.locationStaleSeconds, n('locationStaleSeconds'));
    expect(Tunables.disputeWindowHours, n('disputeWindowHours'));
    expect(Tunables.nearbyRadiusKm, n('nearbyRadiusKm'));
    expect(Tunables.minorPerUnit, n('minorPerUnit'));
  });
}
