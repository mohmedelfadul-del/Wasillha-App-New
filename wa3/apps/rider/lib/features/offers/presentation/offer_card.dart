import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// One driver's offer, laid out the same way as every other for comparison.
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer, required this.proposedFare, required this.onAccept, required this.busy});
  final Offer offer;
  final int? proposedFare;

  /// Null while another accept is in flight.
  final VoidCallback? onAccept;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final o = offer;
    final rating = o.driver.ratingAvg;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(WSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Wraps the price under the name on narrow screens / large text.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: WSpace.sm,
              runSpacing: WSpace.xs,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(o.driver.name, style: theme.textTheme.titleMedium),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 18, color: WColors.warning),
                        const SizedBox(width: WSpace.xs),
                        Flexible(
                          child: Text(
                            rating == null ? s.t('سائق جديد', 'New driver') : ltr(rating.toStringAsFixed(1)),
                            semanticsLabel: rating == null ? null : '${s.t('التقييم', 'Rating')} ${rating.toStringAsFixed(1)}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  money(o.price, ar: s.ar),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: WSpace.sm),
            Text('${o.vehicle.title} · ${s.category(o.vehicle.category)}', style: theme.textTheme.bodyMedium),
            const SizedBox(height: WSpace.xs),
            Wrap(
              spacing: WSpace.lg,
              runSpacing: WSpace.xs,
              children: [
                Text('${s.t('يصل خلال', 'Arrives in')} ${minutes(o.etaMinutes * 60, ar: s.ar)}'),
                if (proposedFare != null && proposedFare != o.price)
                  Text(
                    '${s.t('سعرك', 'Your price')} ${money(proposedFare!, ar: s.ar)}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: WSpace.sm),
            Countdown(
              until: o.expiresAt,
              builder: (context, left) {
                final frac = (left.inMilliseconds / (Tunables.offerTtlSeconds * 1000)).clamp(0.0, 1.0);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${s.t('ينتهي العرض بعد', 'Offer expires in')} ${mmss(left)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: left.inSeconds <= 10 ? WColors.warning : theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: WSpace.xs),
                    ExcludeSemantics(
                      child: LinearProgressIndicator(value: frac, minHeight: 4, borderRadius: BorderRadius.circular(2)),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: WSpace.md),
            FilledButton(
              onPressed: onAccept,
              child: busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text('${s.t('اقبل', 'Accept')} ${money(o.price, ar: s.ar)}', textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
