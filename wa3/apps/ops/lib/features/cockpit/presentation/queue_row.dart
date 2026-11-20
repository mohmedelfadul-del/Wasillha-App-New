import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../../../app/routes.dart';
import '../../../app/sections.dart';
import '../../../app/services.dart';
import '../../../app/widgets/failure.dart';
import '../../../app/widgets/fields.dart';
import '../../../app/widgets/now_builder.dart';
import '../../../app/widgets/stale_notice.dart';
import '../../auth/application/session_controller.dart';
import '../domain/cockpit_repository.dart';

/// One work queue with count, oldest age, owner, and a link to its screen.
class QueueRow extends StatefulWidget {
  const QueueRow({super.key, required this.kind});
  final QueueKind kind;
  @override
  State<QueueRow> createState() => _QueueRowState();
}

class _QueueRowState extends State<QueueRow> {
  Stream<Live<QueueSummary>>? _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stream ??= context.services.cockpit.watch(widget.kind);
  }

  void _retry() => setState(() => _stream = context.services.cockpit.watch(widget.kind));

  String _title(S s) => switch (widget.kind) {
        QueueKind.kycPending => s.t('وثائق بانتظار المراجعة', 'KYC documents waiting'),
        QueueKind.urgentSafety => s.t('بلاغات سلامة عاجلة', 'Urgent safety reports'),
        QueueKind.openCases => s.t('اعتراضات وطلبات دعم مفتوحة', 'Open disputes & support cases'),
        QueueKind.flaggedTrips => s.t('رحلات متعثرة أو موقعها قديم', 'Stuck or stale live trips'),
      };

  void _open() => switch (widget.kind) {
        QueueKind.kycPending => openSection(context, Section.kyc),
        QueueKind.urgentSafety => Navigator.of(context).pushNamed('/cases?filter=urgent'),
        QueueKind.openCases => openSection(context, Section.cases),
        QueueKind.flaggedTrips => openSection(context, Section.trips),
      };

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.outline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _open,
        child: Padding(
          padding: const EdgeInsets.all(WSpace.lg),
          child: StreamBuilder<Live<QueueSummary>>(
            stream: _stream,
            builder: (context, snap) {
              final header = Row(children: [
                Expanded(child: Semantics(header: true, child: Text(_title(s), style: theme.textTheme.titleMedium))),
                Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, semanticLabel: s.t('فتح', 'Open')),
              ]);
              if (snap.hasError) {
                final f = snap.error is ApiFailure ? snap.error as ApiFailure : ApiFailure('internal', '${snap.error}');
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  header,
                  const SizedBox(height: WSpace.sm),
                  StatusBadge(tone: Tone.error, label: f.isNetwork ? s.offlineTitle : s.somethingWrong),
                  const SizedBox(height: WSpace.xs),
                  Text(describeFailure(s, f)),
                  TextButton(onPressed: _retry, child: Text(s.retry)),
                ]);
              }
              final live = snap.data;
              if (live == null) {
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  header,
                  const SizedBox(height: WSpace.sm),
                  Semantics(label: s.loading, child: const LinearProgressIndicator()),
                ]);
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                header,
                const SizedBox(height: WSpace.sm),
                StaleNotice(fromCache: live.fromCache),
                NowBuilder(builder: (context, now) => _Summary(q: live.value, now: now)),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.q, required this.now});
  final QueueSummary q;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final me = context.myUid;
    final countText = ltr('${q.count}${q.countIsLowerBound ? '+' : ''}');
    if (q.count == 0) return StatusBadge(tone: Tone.success, label: s.t('لا شيء بالانتظار', 'Nothing waiting'));
    final tone = q.kind == QueueKind.urgentSafety || q.kind == QueueKind.flaggedTrips ? Tone.error : Tone.warning;
    String owner(String? uid) => uid == null ? s.t('بلا مسؤول', 'Unowned') : uid == me ? s.t('أنت', 'You') : ltr(shortId(uid));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: WSpace.md, runSpacing: WSpace.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(countText, style: Theme.of(context).textTheme.headlineMedium, semanticsLabel: s.t('العدد $countText', 'Count $countText')),
        StatusBadge(tone: tone, label: s.t('بانتظار إجراء', 'Needs action')),
      ]),
      if (q.oldestAt != null) Field(s.t('الأقدم ينتظر منذ', 'Oldest waiting'), age(q.oldestAt!, now, ar: s.ar)),
      if (q.kind == QueueKind.flaggedTrips) ...[
        Field(s.t('متعثرة', 'Stuck'), ltr('${q.stuck}')),
        Field(s.t('موقع السائق قديم', 'Driver location stale'), ltr('${q.stale}')),
      ] else ...[
        Field(q.kind == QueueKind.kycPending ? s.t('محجوز الأقدم لدى', 'Oldest claimed by') : s.t('مسؤول الأقدم', 'Oldest owner'), owner(q.oldestOwner)),
        Field(q.kind == QueueKind.kycPending ? s.t('غير محجوزة', 'Unclaimed') : s.t('بلا مسؤول', 'Unowned'), ltr('${q.unowned}')),
      ],
    ]);
  }
}
