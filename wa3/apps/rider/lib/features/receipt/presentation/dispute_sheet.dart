import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';

/// Report a problem with a completed trip (within 48 h) → `disputeTrip`.
Future<void> showDisputeSheet(BuildContext context, Trip trip) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DisputeSheet(trip: trip),
  );
  if (sent == true && context.mounted) {
    showSuccess(context, context.s.t('أُرسل اعتراضك. سيراجعه فريق وصلها.', 'Your report was sent. The Wasilha team will review it.'));
  }
}

class _DisputeSheet extends StatefulWidget {
  const _DisputeSheet({required this.trip});
  final Trip trip;
  @override
  State<_DisputeSheet> createState() => _DisputeSheetState();
}

class _DisputeSheetState extends State<_DisputeSheet> {
  final _text = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = context.s;
    final reason = _text.text.trim();
    if (reason.length < 10) {
      setState(() => _error = s.t('اشرح المشكلة (10 أحرف على الأقل).', 'Explain the problem (at least 10 characters).'));
      return;
    }
    final ok = await confirmAction(context,
        title: s.t('إرسال الاعتراض؟', 'Send this report?'),
        body: s.t('ستصبح الرحلة قيد المراجعة حتى يرد فريق وصلها.', 'The trip will be under review until the Wasilha team responds.'),
        confirmLabel: s.t('أرسل', 'Send'));
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.deps.trips.disputeTrip(tripId: widget.trip.id, reason: reason, expectedRevision: widget.trip.revision, key: IntentKey.generate());
      if (mounted) Navigator.of(context).pop(true);
    } on ApiFailure catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = s.error(e.code, e.message);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: EdgeInsets.fromLTRB(WSpace.lg, 0, WSpace.lg, MediaQuery.viewInsetsOf(context).bottom + WSpace.lg),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(s.t('الإبلاغ عن مشكلة في الرحلة', 'Report a problem with this trip'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: WSpace.sm),
          Text(s.t('مثلاً: المبلغ المدفوع غير صحيح، أو لم تتم الرحلة كما يجب.', 'For example: the amount paid was wrong, or the trip didn’t happen as it should.')),
          const SizedBox(height: WSpace.md),
          TextField(
            controller: _text,
            maxLines: 4,
            maxLength: 1000,
            enabled: !_busy,
            decoration: InputDecoration(labelText: s.t('ما المشكلة؟', 'What went wrong?'), errorText: _error, errorMaxLines: 3),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: WSpace.md),
          FilledButton(
            onPressed: _busy ? null : _send,
            child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)) : Text(s.t('أرسل', 'Send')),
          ),
          TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(false), child: Text(s.t('رجوع', 'Go back'))),
        ]),
      ),
    );
  }
}
