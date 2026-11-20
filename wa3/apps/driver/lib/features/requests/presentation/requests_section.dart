import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../../../app/services.dart';
import '../../../app/widgets/stale_notice.dart';
import '../domain/offer_math.dart';
import 'offer_sheet.dart';
import 'request_card_view.dart';

/// Live nearby requests while online. Expired cards disappear on the second.
class RequestsSection extends StatefulWidget {
  const RequestsSection({super.key, required this.uid});
  final String uid;
  @override
  State<RequestsSection> createState() => _RequestsSectionState();
}

class _RequestsSectionState extends State<RequestsSection> {
  late Stream<Live<List<RequestCard>>> _inbox = context.services.requests.watchInbox(widget.uid);
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _open(RequestCard c) async {
    final sent = await showOfferSheet(context, c);
    if (sent == true && mounted) {
      showSuccess(context, context.s.t('أُرسل عرضك. إذا قبله الراكب ستنتقل إلى الرحلة تلقائياً.', 'Offer sent. If the rider accepts, the trip opens automatically.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return StreamBuilder<Live<List<RequestCard>>>(
      stream: _inbox,
      builder: (context, snap) {
        final header = Padding(
          padding: const EdgeInsets.only(bottom: WSpace.sm),
          child: Text(s.t('طلبات قريبة', 'Nearby requests'), style: Theme.of(context).textTheme.titleLarge),
        );
        if (snap.hasError) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            header,
            WStateView.error(context, snap.error!, onRetry: () => setState(() => _inbox = context.services.requests.watchInbox(widget.uid))),
          ]);
        }
        if (!snap.hasData) return Column(children: [header, WStateView.loading()]);
        final now = context.services.clock();
        final cards = liveRequests(snap.data!.data, now);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          header,
          StaleNotice(fromCache: snap.data!.fromCache),
          if (cards.isEmpty)
            WStateView.empty(
              icon: Icons.inbox_outlined,
              title: s.t('لا توجد طلبات قريبة الآن', 'No nearby requests right now'),
              body: s.t('ابقَ متصلاً. تظهر هنا الطلبات الجديدة ضمن 15 كم تلقائياً.', 'Stay online. New requests within 15 km appear here automatically.'),
            )
          else
            for (final c in cards) ...[
              _CardWithOffer(key: ValueKey(c.tripId), card: c, uid: widget.uid, now: now, onTap: () => _open(c)),
              const SizedBox(height: WSpace.md),
            ],
        ]);
      },
    );
  }
}

/// Keeps one subscription to this driver's own offer per card.
class _CardWithOffer extends StatefulWidget {
  const _CardWithOffer({super.key, required this.card, required this.uid, required this.now, required this.onTap});
  final RequestCard card;
  final String uid;
  final DateTime now;
  final VoidCallback onTap;
  @override
  State<_CardWithOffer> createState() => _CardWithOfferState();
}

class _CardWithOfferState extends State<_CardWithOffer> {
  late final Stream<Offer?> _offer = context.services.requests.watchMyOffer(tripId: widget.card.tripId, uid: widget.uid);

  @override
  Widget build(BuildContext context) => StreamBuilder<Offer?>(
        stream: _offer,
        builder: (context, o) => RequestCardView(card: widget.card, now: widget.now, myOffer: o.data, onTap: widget.onTap),
      );
}
