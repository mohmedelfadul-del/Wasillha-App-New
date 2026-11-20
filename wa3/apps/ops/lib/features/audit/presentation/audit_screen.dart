import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';
import '../../../app/widgets/fields.dart';
import '../../../app/widgets/live_view.dart';
import '../domain/audit_repository.dart';

/// Immutable audit log, newest first. Read-only (admin).
class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});
  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  int _limit = 50;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final repo = context.services.audit;
    return LiveView<List<AuditEntry>>(
      key: ValueKey(_limit),
      open: () => repo.recent(limit: _limit),
      isEmpty: (l) => l.isEmpty,
      empty: (_) => WStateView.empty(icon: Icons.history_edu_outlined, title: s.t('السجل فارغ', 'The audit log is empty')),
      builder: (context, list) => ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: WSpace.sm),
        itemCount: list.length + 1,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, i) {
          if (i == list.length) {
            return list.length < _limit
                ? Padding(padding: const EdgeInsets.all(WSpace.lg), child: Text(s.t('نهاية السجل', 'End of the log'), textAlign: TextAlign.center))
                : Padding(
                    padding: const EdgeInsets.all(WSpace.lg),
                    child: OutlinedButton(onPressed: () => setState(() => _limit += 50), child: Text(s.t('عرض المزيد', 'Show more'))),
                  );
          }
          final e = list[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: WSpace.lg, vertical: WSpace.sm),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: WSpace.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(ltr(e.action), style: Theme.of(context).textTheme.titleSmall),
                Text(dateTime(e.at), style: Theme.of(context).textTheme.bodySmall),
              ]),
              Field(s.t('المنفّذ', 'Actor'), '${ltr(e.actor)} · ${e.role}', selectable: true),
              Field(s.t('الهدف', 'Target'), ltr(e.target), selectable: true),
              if (e.data.isNotEmpty)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(const JsonEncoder.withIndent('  ').convert(e.data), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
            ]),
          );
        },
      ),
    );
  }
}
