import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/sections.dart';
import '../../../app/widgets/fields.dart';
import '../../../app/widgets/reason_dialog.dart';
import '../../auth/application/session_controller.dart';
import '../domain/kyc_repository.dart';
import 'kyc_labels.dart';

/// One KYC document in its current claim state. Claim to see the file and
/// decide; reject / request changes require a reason.
class KycReviewPanel extends StatelessWidget {
  const KycReviewPanel({
    super.key,
    required this.doc,
    required this.now,
    this.subject,
    required this.onClaim,
    required this.onDecide,
    this.filePreview,
  });
  final ReviewDocument doc;
  final DateTime now;
  final ReviewSubject? subject;
  final Future<void> Function() onClaim;
  final Future<void> Function(Decision decision, String? reason) onDecide;

  /// Shown only while I hold the claim.
  final Widget? filePreview;

  Future<void> _decide(BuildContext context, Decision d) async {
    final s = context.s;
    final type = docTypeLabel(s, doc.type);
    if (d == Decision.approved) {
      final ok = await confirmAction(
        context,
        title: s.t('اعتماد $type؟', 'Approve $type?'),
        body: s.t('يُعتمد السائق أو المركبة تلقائياً عند اعتماد جميع الوثائق المطلوبة.', 'The driver or vehicle becomes approved once all required documents are approved.'),
        confirmLabel: s.t('اعتماد', 'Approve'),
      );
      if (ok) await onDecide(d, null);
      return;
    }
    final reject = d == Decision.rejected;
    final reason = await askReason(
      context,
      title: reject ? s.t('رفض $type', 'Reject $type') : s.t('طلب تعديل $type', 'Request changes to $type'),
      body: s.t('سيرى السائق هذا السبب. اكتبه بوضوح.', 'The driver will see this reason. Write it clearly.'),
      label: s.t('السبب', 'Reason'),
      confirmLabel: reject ? s.t('رفض', 'Reject') : s.t('طلب تعديل', 'Request changes'),
      destructive: reject,
    );
    if (reason != null) await onDecide(d, reason);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final me = context.myUid;
    final t = Theme.of(context).textTheme;
    final claim = claimStateOf(doc, me, now);
    final canReview = Can.reviewKyc(context.role);
    final until = doc.claimedAt?.add(claimTtl);

    return PageBody(children: [
      Wrap(spacing: WSpace.sm, runSpacing: WSpace.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Semantics(header: true, child: Text(docTypeLabel(s, doc.type), style: t.titleLarge)),
        StatusBadge(tone: reviewTone(doc.status), label: s.review(doc.status)),
        if (claim != ClaimState.decided) StatusBadge(tone: claimTone(claim), label: claimLabel(s, claim, doc.claimedBy)),
      ]),
      const SizedBox(height: WSpace.sm),
      Field(s.t('السائق', 'Driver'), subject == null ? ltr(doc.driverId) : '${subject!.driverName}${subject!.driverPhone?.isNotEmpty == true ? ' · ${ltr(subject!.driverPhone!)}' : ''}'),
      if (doc.vehicleId != null)
        Field(s.t('المركبة', 'Vehicle'), subject?.plate == null ? ltr(doc.vehicleId!) : '${subject!.vehicleTitle ?? ''} · ${ltr(subject!.plate!)}'),
      Field(s.t('أُرسلت', 'Submitted'), '${clock(doc.submittedAt)} · ${age(doc.submittedAt, now, ar: s.ar)}'),
      Field(s.t('المسار', 'Path'), ltr(doc.path), selectable: true),
      const SizedBox(height: WSpace.md),
      ...switch (claim) {
        ClaimState.decided => [
            Field(s.t('القرار', 'Decision'), s.review(doc.status)),
            if (doc.reason != null) Field(s.t('السبب', 'Reason'), doc.reason!),
            Field(s.t('قرّره', 'Decided by'), whoLabel(s, doc.decidedBy, me)),
            if (doc.decidedAt != null) Field(s.t('وقت القرار', 'Decided at'), '${clock(doc.decidedAt!)} · ${age(doc.decidedAt!, now, ar: s.ar)}'),
          ],
        ClaimState.other => [
            WBanner(
              tone: Tone.warning,
              text: s.t('يراجع هذا العنصر: ${ltr(doc.claimedBy!)}', 'Being reviewed by: ${ltr(doc.claimedBy!)}') +
                  (until == null ? '' : s.t(' · حتى ${clock(until)}', ' · until ${clock(until)}')),
            ),
          ],
        ClaimState.unclaimed => [
            Text(s.t('احجز العنصر لعرض الملف واتخاذ القرار. يبقى الحجز ١٥ دقيقة.', 'Claim this item to view the file and decide. A claim lasts 15 minutes.')),
            const SizedBox(height: WSpace.md),
            if (canReview) PrimaryAction(label: s.t('احجز للمراجعة', 'Claim for review'), icon: Icons.lock_open, onPressed: onClaim),
          ],
        ClaimState.mine => [
            WBanner(tone: Tone.success, text: s.t('أنت تحجز هذا العنصر', 'You hold this item') + (until == null ? '' : s.t(' حتى ${clock(until)}', ' until ${clock(until)}'))),
            const SizedBox(height: WSpace.md),
            ?filePreview,
            const SizedBox(height: WSpace.lg),
            PrimaryAction(label: s.t('اعتماد', 'Approve'), icon: Icons.check, onPressed: () => _decide(context, Decision.approved)),
            const SizedBox(height: WSpace.sm),
            OutlinedButton.icon(
              key: const Key('request-changes'),
              onPressed: () => _decide(context, Decision.changesRequested),
              icon: const Icon(Icons.edit_note),
              label: Text(s.t('طلب تعديل', 'Request changes')),
            ),
            const SizedBox(height: WSpace.sm),
            OutlinedButton.icon(
              key: const Key('reject'),
              style: OutlinedButton.styleFrom(foregroundColor: WColors.error),
              onPressed: () => _decide(context, Decision.rejected),
              icon: const Icon(Icons.close),
              label: Text(s.t('رفض', 'Reject')),
            ),
          ],
      },
    ]);
  }
}
