import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';
import '../../common/domain/live.dart';
import '../../common/presentation/cache_banner.dart';
import '../../common/presentation/ticking.dart';
import '../../trip/presentation/cancel_flow.dart';
import 'offer_card.dart';

/// Open request: calm waiting state, then live, comparable offers.
class OffersView extends StatefulWidget {
  const OffersView({super.key, required this.trip, this.fromCache = false});
  final Trip trip;
  final bool fromCache;
  @override
  State<OffersView> createState() => _OffersViewState();
}

class _OffersViewState extends State<OffersView> {
  late Stream<Live<List<Offer>>> _offers = context.deps.trips.watchOffers(widget.trip.id);
  String? _accepting;

  Future<void> _accept(Offer o) async {
    setState(() => _accepting = o.id);
    try {
      await context.deps.trips.acceptOffer(tripId: widget.trip.id, offerId: o.id, expectedRevision: widget.trip.revision, key: IntentKey.generate());
      // The trip listener moves to the live trip once the server assigns the driver.
    } on ApiFailure catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _accepting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = widget.trip;
    return Scaffold(
      appBar: AppBar(title: Text(s.state(t.state))),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CacheBanner(fromCache: widget.fromCache),
          Expanded(
            child: StreamBuilder<Live<List<Offer>>>(
              stream: _offers,
              builder: (context, snap) => Ticking(builder: (context, now) => _content(context, snap, now)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(WSpace.lg, WSpace.xs, WSpace.lg, WSpace.md),
          child: OutlinedButton.icon(
            onPressed: _accepting == null ? () => cancelTripWithReason(context, t) : null,
            icon: const Icon(Icons.close),
            label: Text(s.t('إلغاء الطلب', 'Cancel request')),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, AsyncSnapshot<Live<List<Offer>>> snap, DateTime now) {
    final s = context.s;
    final theme = Theme.of(context);
    final t = widget.trip;
    final live = (snap.data?.value ?? const <Offer>[]).where((o) => o.isLive(now)).toList()
      ..sort((a, b) => a.price != b.price ? a.price.compareTo(b.price) : a.etaMinutes.compareTo(b.etaMinutes));
    final expires = t.expiresAt;
    final timeUp = expires != null && !expires.isAfter(now);

    final header = Card(
      child: Padding(
        padding: const EdgeInsets.all(WSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.t('إلى', 'To')}: ${t.dropoff.label}', style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            Text('${s.category(t.category)}${t.proposedFare == null ? '' : ' · ${s.t('سعرك', 'Your price')} ${money(t.proposedFare!, ar: s.ar)}'}'),
            if (expires != null)
              Text(
                timeUp
                    ? s.t('انتهت مدة الطلب. ننتظر تأكيد الخادم…', 'Time is up. Waiting for the server to close the request…')
                    : '${s.t('يبقى الطلب مفتوحاً لمدة', 'Request stays open for')} ${mmss(expires.difference(now))}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );

    final Widget body;
    if (snap.hasError) {
      body = WStateView.error(context, snap.error!, onRetry: () => setState(() => _offers = context.deps.trips.watchOffers(t.id)));
    } else if (!snap.hasData) {
      body = WStateView.loading(label: s.loading);
    } else if (live.isEmpty) {
      body = _Waiting(timeUp: timeUp);
    } else {
      return ListView(
        padding: const EdgeInsets.all(WSpace.lg),
        children: [
          header,
          const SizedBox(height: WSpace.lg),
          CacheBanner(fromCache: snap.data!.fromCache),
          Semantics(
            liveRegion: true,
            child: Text(
              live.length == 1 ? s.t('عرض واحد', '1 offer') : '${ltr('${live.length}')} ${s.t('عروض', 'offers')}',
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: WSpace.sm),
          for (final o in live) ...[
            OfferCard(
              key: ValueKey(o.id),
              offer: o,
              proposedFare: t.proposedFare,
              busy: _accepting == o.id,
              onAccept: _accepting == null ? () => _accept(o) : null,
            ),
            const SizedBox(height: WSpace.md),
          ],
        ],
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(WSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: WSpace.lg),
          body,
        ],
      ),
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.timeUp});
  final bool timeUp;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: WSpace.xl),
        child: Column(
          children: [
            const Icon(Icons.local_taxi_outlined, size: 40),
            const SizedBox(height: WSpace.md),
            Text(s.t('نبحث عن سائقين قريبين', 'Finding drivers near you'), style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: WSpace.sm),
            Text(
              timeUp
                  ? s.t('لم تصل عروض بعد.', 'No offers have arrived.')
                  : s.t(
                      'أُرسل طلبك للسائقين القريبين. ستظهر عروضهم هنا لتختار واحداً.',
                      'Your request went to nearby drivers. Their offers will appear here for you to choose.',
                    ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
