import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';

/// 1–5 stars + optional comment → `rateTrip` (once, after completion).
class RatingForm extends StatefulWidget {
  const RatingForm({super.key, required this.trip});
  final Trip trip;
  @override
  State<RatingForm> createState() => _RatingFormState();
}

class _RatingFormState extends State<RatingForm> {
  int _stars = 0;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final c = _comment.text.trim();
    await context.deps.trips.rateTrip(tripId: widget.trip.id, stars: _stars, comment: c.isEmpty ? null : c, key: IntentKey.generate());
    if (mounted) showSuccess(context, context.s.t('شكراً، وصل تقييمك.', 'Thanks — your rating was sent.'));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('${s.t('قيّم رحلتك مع', 'Rate your trip with')} ${widget.trip.driver?.name ?? ''}', style: theme.textTheme.titleMedium),
      const SizedBox(height: WSpace.sm),
      Wrap(alignment: WrapAlignment.center, children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: s.t('$i من 5', '$i of 5'),
            iconSize: 36,
            isSelected: i <= _stars,
            icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded, color: i <= _stars ? WColors.warning : theme.colorScheme.onSurfaceVariant),
            onPressed: () => setState(() => _stars = i),
          ),
      ]),
      const SizedBox(height: WSpace.sm),
      TextField(
        controller: _comment,
        maxLines: 3,
        maxLength: 500,
        decoration: InputDecoration(labelText: s.t('تعليق (اختياري)', 'Comment (optional)')),
      ),
      const SizedBox(height: WSpace.sm),
      if (_stars == 0)
        Padding(
          padding: const EdgeInsets.only(bottom: WSpace.sm),
          child: Text(s.t('اختر عدد النجوم للإرسال.', 'Choose a number of stars to send.'), style: theme.textTheme.bodySmall),
        ),
      PrimaryAction(label: s.t('أرسل التقييم', 'Send rating'), onPressed: _stars == 0 ? null : _send),
    ]);
  }
}
