import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// Asks for a free-text reason; the confirm button stays disabled until a
/// non-blank reason is typed. Returns the trimmed reason or null.
Future<String?> askReason(
  BuildContext context, {
  required String title,
  String? body,
  required String label,
  required String confirmLabel,
  bool destructive = false,
  int maxLength = 500,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => ReasonDialog(title: title, body: body, label: label, confirmLabel: confirmLabel, destructive: destructive, maxLength: maxLength),
  );
}

class ReasonDialog extends StatefulWidget {
  const ReasonDialog({super.key, required this.title, this.body, required this.label, required this.confirmLabel, this.destructive = false, this.maxLength = 500});
  final String title;
  final String? body;
  final String label;
  final String confirmLabel;
  final bool destructive;
  final int maxLength;
  @override
  State<ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<ReasonDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final ok = _c.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (widget.body != null) ...[Text(widget.body!), const SizedBox(height: WSpace.md)],
        TextField(
          key: const Key('reason-field'),
          controller: _c,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          maxLength: widget.maxLength,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: ok ? null : s.t('السبب مطلوب', 'A reason is required'),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(s.t('رجوع', 'Go back'))),
        FilledButton(
          key: const Key('reason-confirm'),
          style: widget.destructive ? FilledButton.styleFrom(backgroundColor: WColors.error, foregroundColor: Colors.white) : null,
          onPressed: ok ? () => Navigator.pop(context, _c.text.trim()) : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
