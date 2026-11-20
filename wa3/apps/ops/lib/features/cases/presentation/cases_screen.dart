import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/routes.dart';
import '../../../app/services.dart';
import '../../../app/widgets/fields.dart';
import '../../../app/widgets/live_view.dart';
import '../../../app/widgets/now_builder.dart';
import '../../auth/application/session_controller.dart';
import '../domain/cases_repository.dart';
import 'case_labels.dart';

/// Open and in-progress cases by status, oldest first, with age and owner.
class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key, this.urgentOnly = false});
  final bool urgentOnly;
  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  late bool _urgentOnly = widget.urgentOnly;
  bool _unownedOnly = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final repo = context.services.cases;
    return LiveView<List<CaseRecord>>(
      open: () => repo.open(),
      builder: (context, all) {
        final list = all.where((c) => (!_urgentOnly || c.urgent) && (!_unownedOnly || c.c.ownerId == null)).toList();
        final open = list.where((c) => c.c.status == 'open').toList();
        final working = list.where((c) => c.c.status == 'inProgress').toList();
        return NowBuilder(
          builder: (context, now) => ListView(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(WSpace.lg, WSpace.md, WSpace.lg, WSpace.sm),
              child: Wrap(spacing: WSpace.sm, runSpacing: WSpace.sm, children: [
                FilterChip(label: Text(s.t('العاجلة فقط', 'Urgent only')), selected: _urgentOnly, onSelected: (v) => setState(() => _urgentOnly = v)),
                FilterChip(label: Text(s.t('بلا مسؤول فقط', 'Unowned only')), selected: _unownedOnly, onSelected: (v) => setState(() => _unownedOnly = v)),
              ]),
            ),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(WSpace.xl),
                child: WStateView.empty(icon: Icons.task_alt, title: s.t('لا توجد بلاغات مفتوحة هنا', 'No open cases here')),
              ),
            for (final (title, group) in [(caseStatusLabel(s, 'open'), open), (caseStatusLabel(s, 'inProgress'), working)])
              if (group.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(WSpace.lg, WSpace.md, WSpace.lg, WSpace.xs),
                  child: Semantics(header: true, child: Text('$title · ${ltr('${group.length}')}', style: Theme.of(context).textTheme.titleMedium)),
                ),
                for (final c in group) ...[CaseTile(record: c, now: now), const Divider()],
              ],
          ]),
        );
      },
    );
  }
}

class CaseTile extends StatelessWidget {
  const CaseTile({super.key, required this.record, required this.now});
  final CaseRecord record;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = record.c;
    return InkWell(
      onTap: () => openCase(context, c.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: WSpace.lg, vertical: WSpace.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: WSpace.sm, runSpacing: WSpace.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(caseTypeLabel(s, c.type), style: Theme.of(context).textTheme.titleMedium),
            if (record.urgent) StatusBadge(tone: Tone.error, label: s.t('عاجل', 'Urgent')),
            StatusBadge(tone: caseStatusTone(c.status), label: caseStatusLabel(s, c.status)),
          ]),
          const SizedBox(height: WSpace.xs),
          Text('${s.t('ينتظر منذ', 'Waiting')}: ${age(c.createdAt, now, ar: s.ar)} · ${s.t('المسؤول', 'Owner')}: ${ownerLabel(s, c.ownerId, context.myUid)}'),
          Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
          if (c.tripId != null) Text('${s.t('الرحلة', 'Trip')} ${ltr(shortId(c.tripId!))}', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}
