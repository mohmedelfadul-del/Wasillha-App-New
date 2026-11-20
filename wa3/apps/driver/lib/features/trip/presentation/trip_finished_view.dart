import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/widgets/info_row.dart';
import '../../../app/widgets/stale_notice.dart';
import '../application/active_trip_controller.dart';
import '../domain/stage_action.dart';

/// Completed (summary + rate the rider) or cancelled (who and why).
class TripFinishedView extends StatefulWidget {
  const TripFinishedView({super.key, required this.trip, required this.controller, required this.onDone, required this.fromCache});
  final Trip trip;
  final ActiveTripController controller;
  final VoidCallback onDone;
  final bool fromCache;
  @override
  State<TripFinishedView> createState() => _TripFinishedViewState();
}

class _TripFinishedViewState extends State<TripFinishedView> {
  int _stars = 0;
  final _comment = TextEditingController();
  bool _starsMissing = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _rate() async {
    if (_stars == 0) {
      setState(() => _starsMissing = true);
      return;
    }
    await widget.controller.rate(_stars, _comment.text.trim().isEmpty ? null : _comment.text.trim());
    if (mounted) showSuccess(context, context.s.t('شكراً، أُرسل تقييمك.', 'Thanks, your rating was sent.'));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = widget.trip;
    final completed = t.state == TripState.completed || t.state == TripState.disputed;
    final canRate = completed && t.driverRating == null;
    final back = s.t('العودة إلى العمل', 'Back to work');
    return Scaffold(
      appBar: AppBar(title: Text(driverStageTitle(s, t.state)), automaticallyImplyLeading: false),
      body: ListView(padding: const EdgeInsets.all(WSpace.lg), children: [
        StaleNotice(fromCache: widget.fromCache),
        if (completed)
          Section(children: [
            StatusBadge(tone: Tone.success, label: s.state(TripState.completed)),
            const SizedBox(height: WSpace.sm),
            InfoRow(label: s.t('الأجرة', 'Fare'), value: money(t.fare ?? 0, ar: s.ar)),
            if (t.cashAmount != null) InfoRow(label: s.t('سجّلت أنك استلمت', 'You recorded receiving'), value: money(t.cashAmount!, ar: s.ar)),
            if (t.state == TripState.disputed) Text(s.t('هذه الرحلة محل اعتراض ويراجعها فريقنا.', 'This trip is disputed and our team is reviewing it.')),
          ])
        else
          Section(children: [
            StatusBadge(tone: Tone.warning, label: s.state(TripState.cancelled)),
            const SizedBox(height: WSpace.sm),
            if (t.cancellation != null) ...[
              InfoRow(
                label: s.t('ألغاها', 'Cancelled by'),
                value: switch (t.cancellation!.actor) {
                  'rider' => s.t('الراكب', 'The rider'),
                  'driver' => s.t('أنت', 'You'),
                  'ops' => s.t('فريق العمليات', 'Operations team'),
                  _ => s.t('النظام', 'The system'),
                },
              ),
              InfoRow(label: s.t('السبب', 'Reason'), value: s.cancelReason(t.cancellation!.reason)),
            ],
          ]),
        if (canRate) ...[
          const SizedBox(height: WSpace.lg),
          Section(title: s.t('قيّم الراكب', 'Rate the rider'), children: [
            Wrap(alignment: WrapAlignment.center, children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  iconSize: 36,
                  constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
                  tooltip: '${ltr('$i')} / ${ltr('5')}',
                  onPressed: () => setState(() {
                    _stars = i;
                    _starsMissing = false;
                  }),
                  icon: Icon(i <= _stars ? Icons.star : Icons.star_border, color: i <= _stars ? WColors.warning : null),
                ),
            ]),
            if (_starsMissing) Text(s.t('اختر عدد النجوم.', 'Choose a number of stars.'), style: const TextStyle(color: WColors.error)),
            TextField(controller: _comment, maxLength: 500, maxLines: 2, decoration: InputDecoration(labelText: s.t('تعليق (اختياري)', 'Comment (optional)'))),
          ]),
        ] else if (t.driverRating != null) ...[
          const SizedBox(height: WSpace.lg),
          Text('${s.t('قيّمت الراكب', 'You rated the rider')} ${ltr('${t.driverRating!.stars}')} / ${ltr('5')}'),
        ],
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(WSpace.lg),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (canRate) ...[
              PrimaryAction(label: s.t('أرسل التقييم', 'Send rating'), large: true, onPressed: _rate),
              TextButton(onPressed: widget.onDone, child: Text(back)),
            ] else
              PrimaryAction(label: back, large: true, onPressed: () async => widget.onDone()),
          ]),
        ),
      ),
    );
  }
}
