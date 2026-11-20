import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';

/// In-trip safety report → `reportSafety` (an urgent case for operations).
Future<void> showSafetySheet(BuildContext context, Trip trip) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SafetySheet(trip: trip),
  );
  if (sent == true && context.mounted) {
    showSuccess(context, context.s.t('أُرسل البلاغ. فريق السلامة في وصلها تم تنبيهه.', 'Report sent. Wasilha’s safety team has been alerted.'));
  }
}

class _SafetySheet extends StatefulWidget {
  const _SafetySheet({required this.trip});
  final Trip trip;
  @override
  State<_SafetySheet> createState() => _SafetySheetState();
}

class _SafetySheetState extends State<_SafetySheet> {
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
    final d = _text.text.trim();
    if (d.length < 5) {
      setState(() => _error = s.t('صف ما يحدث (5 أحرف على الأقل).', 'Describe what is happening (at least 5 characters).'));
      return;
    }
    final ok = await confirmAction(
      context,
      title: s.t('إرسال بلاغ السلامة؟', 'Send safety report?'),
      body: s.t('سيصل البلاغ فوراً إلى فريق السلامة مع تفاصيل الرحلة.', 'The report goes straight to the safety team with the trip details.'),
      confirmLabel: s.t('أرسل', 'Send'),
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.deps.trips.reportSafety(tripId: widget.trip.id, description: d, key: IntentKey.generate());
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
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(WSpace.lg, 0, WSpace.lg, MediaQuery.viewInsetsOf(context).bottom + WSpace.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.t('بلاغ سلامة', 'Safety report'), style: theme.textTheme.titleLarge),
            const SizedBox(height: WSpace.sm),
            Text(s.t('إذا كنت في خطر مباشر، اتصل بخدمات الطوارئ المحلية أولاً.', 'If you are in immediate danger, contact local emergency services first.')),
            const SizedBox(height: WSpace.md),
            TextField(
              controller: _text,
              maxLines: 4,
              maxLength: 1000,
              enabled: !_busy,
              decoration: InputDecoration(labelText: s.t('ماذا يحدث؟', 'What is happening?'), errorText: _error, errorMaxLines: 3),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: WSpace.md),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: WColors.error, foregroundColor: Colors.white),
              onPressed: _busy ? null : _send,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(s.t('أرسل البلاغ', 'Send report')),
            ),
            TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(false), child: Text(s.t('رجوع', 'Go back'))),
          ],
        ),
      ),
    );
  }
}
