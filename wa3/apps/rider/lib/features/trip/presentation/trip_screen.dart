import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';
import '../../common/domain/live.dart';
import '../../live_trip/presentation/live_trip_view.dart';
import '../../offers/presentation/offers_view.dart';
import '../../receipt/presentation/receipt_view.dart';
import 'cancelled_view.dart';

/// Listens to trips/{id} (authoritative) and shows the stage it is in.
class TripScreen extends StatefulWidget {
  const TripScreen({super.key, required this.tripId});
  final String tripId;
  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  late Stream<Live<Trip?>> _stream = context.deps.trips.watchTrip(widget.tripId);

  void _retry() => setState(() => _stream = context.deps.trips.watchTrip(widget.tripId));

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return StreamBuilder<Live<Trip?>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) return Scaffold(appBar: AppBar(), body: WStateView.error(context, snap.error!, onRetry: _retry));
        final live = snap.data;
        // Right after confirming, the cache can still hold the draft: wait for the server.
        final cachedDraft = live?.value?.state == TripState.draft && live!.fromCache;
        if (live == null || (live.value == null && live.fromCache) || cachedDraft) {
          return Scaffold(appBar: AppBar(), body: WStateView.loading(label: s.loading));
        }
        final trip = live.value;
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(),
            body: WStateView.empty(icon: Icons.search_off, title: s.t('لم نجد هذه الرحلة', 'We couldn’t find this trip')),
          );
        }
        final stale = live.fromCache;
        return switch (trip.state) {
          TripState.searching || TripState.offering => OffersView(key: ValueKey('offers-${trip.id}'), trip: trip, fromCache: stale),
          TripState.driverAssigned || TripState.driverEnRoute || TripState.driverArrived || TripState.inProgress || TripState.arrived =>
            LiveTripView(key: ValueKey('live-${trip.id}'), trip: trip, fromCache: stale),
          TripState.paymentPending || TripState.completed || TripState.disputed => ReceiptView(trip: trip, fromCache: stale),
          TripState.cancelled => CancelledView(trip: trip),
          TripState.draft => Scaffold(
              appBar: AppBar(),
              body: WStateView.empty(
                icon: Icons.drafts_outlined,
                title: s.t('لم يُرسل هذا الطلب', 'This request wasn’t sent'),
                body: s.t('ابدأ طلباً جديداً من الشاشة الرئيسية.', 'Start a new request from the home screen.'),
              ),
            ),
        };
      },
    );
  }
}
