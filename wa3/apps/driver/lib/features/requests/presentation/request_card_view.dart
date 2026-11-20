import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// First tap of the two-tap offer. Shows what matters for the decision.
class RequestCardView extends StatelessWidget {
  const RequestCardView({super.key, required this.card, required this.now, required this.onTap, this.myOffer});
  final RequestCard card;
  final DateTime now;
  final VoidCallback onTap;
  final Offer? myOffer;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final left = card.expiresAt.difference(now);
    final offer = myOffer;
    final offerLive = offer != null && offer.isLive(now);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(WSpace.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: WSpace.sm, runSpacing: WSpace.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(money(card.proposedFare, ar: s.ar), style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              StatusBadge(tone: Tone.neutral, label: s.category(card.category)),
            ]),
            const SizedBox(height: WSpace.sm),
            Text('${s.t('إلى الراكب', 'To pickup')}: ${km((card.distanceToPickupKm * 1000).round(), ar: s.ar)}'),
            Text('${s.t('طول الرحلة', 'Trip distance')}: ${km(card.tripDistanceMeters, ar: s.ar)}'),
            Text('${s.t('من', 'From')}: ${card.pickup.label}', maxLines: 2, overflow: TextOverflow.ellipsis),
            Text('${s.t('إلى', 'To')}: ${card.dropoffLabel}', maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: WSpace.sm),
            Row(children: [
              const Icon(Icons.timer_outlined, size: 18),
              const SizedBox(width: WSpace.xs),
              Flexible(child: Text('${s.t('ينتهي بعد', 'Ends in')} ${mmss(left.isNegative ? Duration.zero : left)}')),
            ]),
            if (offer != null) ...[
              const SizedBox(height: WSpace.sm),
              offerLive
                  ? StatusBadge(
                      tone: Tone.info,
                      label: '${s.t('أُرسل عرضك', 'Offer sent')} ${money(offer.price, ar: s.ar)} · ${s.t('بانتظار الراكب', 'waiting for the rider')} ${mmss(offer.expiresAt.difference(now))}',
                    )
                  : StatusBadge(tone: Tone.warning, label: s.t('انتهى عرضك — اضغط لإرسال عرض جديد', 'Your offer expired — tap to send a new one')),
            ] else ...[
              const SizedBox(height: WSpace.sm),
              Text(s.t('اضغط لإرسال عرض', 'Tap to make an offer'), style: t.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
            ],
          ]),
        ),
      ),
    );
  }
}
