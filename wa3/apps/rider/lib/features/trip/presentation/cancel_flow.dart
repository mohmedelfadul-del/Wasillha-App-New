import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';

/// Reason sheet → `cancelTrip` with the revision we rendered.
/// Returns true when the server accepted the cancellation.
Future<bool> cancelTripWithReason(BuildContext context, Trip trip) async {
  final s = context.s;
  final deps = context.deps;
  final requestOpen = trip.state.isOpenRequest;
  final choice = await confirmWithReason(
    context,
    title: requestOpen ? s.t('إلغاء الطلب؟', 'Cancel this request?') : s.t('إلغاء الرحلة؟', 'Cancel this trip?'),
    reasons: [for (final r in cancelReasons['rider']!) (r, s.cancelReason(r))],
    confirmLabel: requestOpen ? s.t('إلغاء الطلب', 'Cancel request') : s.t('إلغاء الرحلة', 'Cancel trip'),
  );
  if (choice == null || !context.mounted) return false;
  try {
    await deps.trips.cancelTrip(
      tripId: trip.id,
      reason: choice.reason,
      note: choice.note,
      expectedRevision: trip.revision,
      key: IntentKey.generate(),
    );
    return true;
  } on ApiFailure catch (e) {
    if (context.mounted) showFailure(context, e);
    return false;
  }
}
