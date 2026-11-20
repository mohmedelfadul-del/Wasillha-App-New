import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';
import '../domain/offer_math.dart';

/// Second tap of the two-tap offer: price prefilled with the rider's fare
/// (adjustable within the quote bounds) and ETA prefilled from distance.
Future<bool?> showOfferSheet(BuildContext context, RequestCard card) => showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => OfferSheet(card: card),
    );

class OfferSheet extends StatefulWidget {
  const OfferSheet({super.key, required this.card});
  final RequestCard card;
  @override
  State<OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<OfferSheet> {
  late final OfferDraft _d = OfferDraft.forCard(widget.card);
  IntentKey? _key;

  void _change(VoidCallback f) => setState(() {
        f();
        _key = null; // a different offer is a different intent
      });

  Future<void> _send() async {
    _key ??= IntentKey.generate();
    await context.services.requests.submitOffer(tripId: widget.card.tripId, price: _d.price, etaMinutes: _d.eta, key: _key!);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = widget.card;
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(WSpace.lg, 0, WSpace.lg, MediaQuery.viewInsetsOf(context).bottom + WSpace.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text(s.t('أرسل عرضك', 'Send your offer'), style: t.titleLarge),
          const SizedBox(height: WSpace.xs),
          Text('${s.t('عرض الراكب', 'Rider offers')}: ${money(c.proposedFare, ar: s.ar)}'),
          Countdown(
            until: c.expiresAt,
            onDone: () {
              if (mounted) Navigator.pop(context, false);
            },
            builder: (_, left) => Text('${s.t('ينتهي الطلب بعد', 'Request ends in')} ${mmss(left)}'),
          ),
          const SizedBox(height: WSpace.lg),
          _Stepper(
            label: s.t('سعرك', 'Your price'),
            value: money(_d.price, ar: s.ar),
            hint: '${s.t('المسموح', 'Allowed')}: ${money(_d.min, ar: s.ar)} – ${money(_d.max, ar: s.ar)}',
            onMinus: _d.canLower ? () => _change(_d.lower) : null,
            onPlus: _d.canRaise ? () => _change(_d.raise) : null,
            minusLabel: s.t('خفّض السعر', 'Lower price'),
            plusLabel: s.t('ارفع السعر', 'Raise price'),
          ),
          const SizedBox(height: WSpace.md),
          _Stepper(
            label: s.t('وقت الوصول إلى الراكب', 'Time to reach the rider'),
            value: minutes(_d.eta * 60, ar: s.ar),
            hint: s.t('تقدير من المسافة. عدّله إن لزم.', 'Estimated from distance. Adjust if needed.'),
            onMinus: _d.canLowerEta ? () => _change(_d.lowerEta) : null,
            onPlus: _d.canRaiseEta ? () => _change(_d.raiseEta) : null,
            minusLabel: s.t('أقل', 'Less time'),
            plusLabel: s.t('أكثر', 'More time'),
          ),
          const SizedBox(height: WSpace.xl),
          PrimaryAction(label: s.t('أرسل العرض', 'Send offer'), large: true, onPressed: _send),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
        ]),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.hint, required this.onMinus, required this.onPlus, required this.minusLabel, required this.plusLabel});
  final String label, value, hint, minusLabel, plusLabel;
  final VoidCallback? onMinus, onPlus;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(WSpace.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(label, style: t.titleSmall),
          Row(children: [
            IconButton.filledTonal(onPressed: onMinus, tooltip: minusLabel, icon: const Icon(Icons.remove), iconSize: 28, constraints: const BoxConstraints(minWidth: 56, minHeight: 56)),
            Expanded(child: Text(value, textAlign: TextAlign.center, style: t.headlineSmall)),
            IconButton.filledTonal(onPressed: onPlus, tooltip: plusLabel, icon: const Icon(Icons.add), iconSize: 28, constraints: const BoxConstraints(minWidth: 56, minHeight: 56)),
          ]),
          Text(hint, style: t.bodySmall, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
