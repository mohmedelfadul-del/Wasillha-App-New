import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/routes.dart';
import '../../../app/services.dart';
import '../../../app/widgets/failure.dart';
import '../../../app/widgets/now_builder.dart';
import '../../../app/widgets/stale_notice.dart';
import '../../auth/application/session_controller.dart';
import '../application/kyc_queue_controller.dart';
import '../domain/kyc_repository.dart';
import 'kyc_labels.dart';

/// Pending documents, oldest first, with who they belong to, age and claim.
class KycQueueScreen extends StatefulWidget {
  const KycQueueScreen({super.key});
  @override
  State<KycQueueScreen> createState() => _KycQueueScreenState();
}

class _KycQueueScreenState extends State<KycQueueScreen> {
  KycQueueController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _c ??= KycQueueController(context.services.kyc);
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = _c!;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        if (c.error != null) return opsErrorView(context, c.error!, onRetry: c.retry);
        final items = c.items;
        if (items == null) return WStateView.loading(label: s.loading);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          StaleNotice(fromCache: c.fromCache),
          Expanded(
            child: items.isEmpty
                ? WStateView.empty(icon: Icons.task_alt, title: s.t('لا توجد وثائق بانتظار المراجعة', 'No documents waiting for review'))
                : NowBuilder(
                    builder: (context, now) => ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: WSpace.sm),
                      itemCount: items.length + 1,
                      separatorBuilder: (_, i) => i == 0 ? const SizedBox.shrink() : const Divider(),
                      itemBuilder: (context, i) => i == 0
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: WSpace.lg, vertical: WSpace.sm),
                              child: Text(s.t('${ltr('${items.length}')} وثيقة، الأقدم أولاً', '${ltr('${items.length}')} documents, oldest first')),
                            )
                          : KycQueueTile(doc: items[i - 1], subject: c.subjects[items[i - 1].path], now: now),
                    ),
                  ),
          ),
        ]);
      },
    );
  }
}

class KycQueueTile extends StatelessWidget {
  const KycQueueTile({super.key, required this.doc, required this.subject, required this.now});
  final ReviewDocument doc;
  final ReviewSubject? subject;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final claim = claimStateOf(doc, context.myUid, now);
    final who = subject == null
        ? ltr(doc.driverId)
        : [subject!.driverName, if (subject!.driverPhone?.isNotEmpty ?? false) ltr(subject!.driverPhone!)].join(' · ');
    final vehicle = doc.vehicleId == null ? null : (subject?.plate != null ? '${subject!.vehicleTitle ?? ''} · ${ltr(subject!.plate!)}' : ltr(doc.vehicleId!));
    return InkWell(
      onTap: () => openReview(context, doc.path),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: WSpace.lg, vertical: WSpace.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: WSpace.sm, runSpacing: WSpace.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(docTypeLabel(s, doc.type), style: t.titleMedium),
            StatusBadge(tone: claimTone(claim), label: claimLabel(s, claim, doc.claimedBy)),
          ]),
          const SizedBox(height: WSpace.xs),
          Text('${s.t('السائق', 'Driver')}: $who'),
          if (vehicle != null) Text('${s.t('المركبة', 'Vehicle')}: $vehicle'),
          Text('${s.t('ينتظر منذ', 'Waiting')}: ${age(doc.submittedAt, now, ar: s.ar)}', style: t.bodySmall),
        ]),
      ),
    );
  }
}
