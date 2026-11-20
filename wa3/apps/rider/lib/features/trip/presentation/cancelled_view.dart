import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';
import '../../request/presentation/request_screen.dart';
import 'trip_screen.dart';

/// A cancelled trip. For "no offers", one tap sends the same request again.
class CancelledView extends StatelessWidget {
  const CancelledView({super.key, required this.trip});
  final Trip trip;

  bool get _noOffers => trip.cancellation?.reason == 'no_offers';

  Future<void> _retry(BuildContext context) async {
    final deps = context.deps;
    final nav = Navigator.of(context);
    final draft = await deps.trips.createDraft(pickup: trip.pickup, dropoff: trip.dropoff, category: trip.category, key: IntentKey.generate());
    final fare = trip.proposedFare;
    if (fare != null && draft.quote.contains(fare)) {
      await deps.trips.confirmRequest(tripId: draft.tripId, proposedFare: fare, expectedRevision: draft.revision, key: IntentKey.generate());
      nav.pushReplacement(MaterialPageRoute(builder: (_) => TripScreen(tripId: draft.tripId)));
      return;
    }
    // The allowed range moved: let the rider choose a fare again (never silently change it).
    nav.pushReplacement(MaterialPageRoute(
      builder: (_) => RequestScreen(pickup: trip.pickup, dropoff: trip.dropoff, category: trip.category, initialDraft: draft, preferredFare: fare),
    ));
  }

  String _who(S s) {
    final c = trip.cancellation;
    if (c == null) return '';
    final reason = s.cancelReason(c.reason);
    return switch (c.actor) {
      'rider' => '${s.t('ألغيت الرحلة', 'You cancelled')}: $reason',
      'driver' => '${s.t('ألغى السائق الرحلة', 'The driver cancelled')}: $reason',
      'ops' => '${s.t('ألغاها فريق وصلها', 'Wasilha support cancelled it')}: $reason',
      _ => reason,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.state(trip.state))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WSpace.xl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Icon(_noOffers ? Icons.hourglass_disabled : Icons.cancel_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: WSpace.md),
            Text(
              _noOffers ? s.t('لم يقبل أي سائق طلبك في الوقت المحدد', 'No driver accepted your request in time') : s.t('أُلغيت الرحلة', 'Trip cancelled'),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: WSpace.sm),
            Text(_noOffers
                ? s.t('انتهت مهلة الطلب دون قبول أي عرض. لم تُحتسب أي رسوم. يمكنك إرسال الطلب نفسه مرة أخرى.',
                    'Your request timed out without an accepted offer. You weren’t charged. You can send the same request again.')
                : _who(s)),
            const SizedBox(height: WSpace.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(WSpace.lg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${s.t('من', 'From')}: ${trip.pickup.label}'),
                  Text('${s.t('إلى', 'To')}: ${trip.dropoff.label}'),
                  Text('${s.category(trip.category)}${trip.proposedFare == null ? '' : ' · ${money(trip.proposedFare!, ar: s.ar)}'}'),
                ]),
              ),
            ),
            const SizedBox(height: WSpace.xl),
            if (_noOffers) ...[
              PrimaryAction(label: s.t('اطلب مرة أخرى', 'Request again'), icon: Icons.refresh, onPressed: () => _retry(context)),
              const SizedBox(height: WSpace.sm),
              TextButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: Text(s.t('العودة للرئيسية', 'Back to home'))),
            ] else
              FilledButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: Text(s.t('العودة للرئيسية', 'Back to home'))),
          ]),
        ),
      ),
    );
  }
}
