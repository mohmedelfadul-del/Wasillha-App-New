import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';

/// The one primary action of a screen. Shows progress while the command runs,
/// disables itself to prevent double taps, and reports failures precisely.
class PrimaryAction extends StatefulWidget {
  const PrimaryAction({super.key, required this.label, required this.onPressed, this.icon, this.large = false, this.destructive = false});
  final String label;

  /// Return normally on success; throw [ApiFailure] to show its message.
  final Future<void> Function()? onPressed;
  final IconData? icon;

  /// Driver app: extra-tall target usable while parked.
  final bool large;
  final bool destructive;

  @override
  State<PrimaryAction> createState() => _PrimaryActionState();
}

class _PrimaryActionState extends State<PrimaryAction> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy || widget.onPressed == null) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } on ApiFailure catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: Size.fromHeight(widget.large ? WSpace.touchLarge : 56),
      backgroundColor: widget.destructive ? WColors.error : null,
      foregroundColor: widget.destructive ? Colors.white : null,
      textStyle: TextStyle(fontSize: widget.large ? 20 : 16, fontWeight: FontWeight.w700),
    );
    return Semantics(
      button: true,
      enabled: widget.onPressed != null && !_busy,
      label: widget.label,
      excludeSemantics: true,
      child: FilledButton(
        style: style,
        onPressed: widget.onPressed == null || _busy ? null : _run,
        child: _busy
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.icon != null) ...[Icon(widget.icon), const SizedBox(width: 8)],
                Flexible(child: Text(widget.label, textAlign: TextAlign.center)),
              ]),
      ),
    );
  }
}

void showFailure(BuildContext context, ApiFailure f) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.s.error(f.code, f.message))));
}

void showSuccess(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(text))]),
    backgroundColor: WColors.success,
  ));
}

/// Rebuilds every second until [until]; [builder] gets the remaining time.
class Countdown extends StatefulWidget {
  const Countdown({super.key, required this.until, required this.builder, this.onDone});
  final DateTime until;
  final Widget Function(BuildContext, Duration remaining) builder;
  final VoidCallback? onDone;
  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  Timer? _t;
  bool _done = false;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (!_done && DateTime.now().isAfter(widget.until)) {
        _done = true;
        widget.onDone?.call();
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.until.difference(DateTime.now());
    return widget.builder(context, r.isNegative ? Duration.zero : r);
  }
}

/// Confirmation with a required reason, for destructive or financial actions.
/// Returns the chosen reason code (and optional note) or null if dismissed.
Future<({String reason, String? note})?> confirmWithReason(
  BuildContext context, {
  required String title,
  required List<(String code, String label)> reasons,
  required String confirmLabel,
  bool noteRequired = false,
  bool destructive = true,
}) {
  String? selected;
  final note = TextEditingController();
  return showModalBottomSheet<({String reason, String? note})>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
      final canConfirm = selected != null && (!noteRequired || note.text.trim().isNotEmpty);
      return Padding(
        padding: EdgeInsets.fromLTRB(WSpace.lg, 0, WSpace.lg, MediaQuery.viewInsetsOf(ctx).bottom + WSpace.lg),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: WSpace.md),
            RadioGroup<String>(
              groupValue: selected,
              onChanged: (v) => set(() => selected = v),
              child: Column(children: [
                for (final (code, label) in reasons)
                  RadioListTile<String>(value: code, title: Text(label), contentPadding: EdgeInsets.zero),
              ]),
            ),
            if (noteRequired || reasons.any((r) => r.$1 == 'other' && selected == 'other')) ...[
              const SizedBox(height: WSpace.sm),
              TextField(
                controller: note,
                maxLines: 3,
                maxLength: 300,
                onChanged: (_) => set(() {}),
                decoration: InputDecoration(labelText: ctx.s.t('ملاحظة', 'Note')),
              ),
            ],
            const SizedBox(height: WSpace.md),
            FilledButton(
              style: destructive ? FilledButton.styleFrom(backgroundColor: WColors.error, foregroundColor: Colors.white) : null,
              onPressed: canConfirm ? () => Navigator.pop(ctx, (reason: selected!, note: note.text.trim().isEmpty ? null : note.text.trim())) : null,
              child: Text(confirmLabel),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.s.t('رجوع', 'Go back'))),
          ]),
        ),
      );
    }),
  );
}

/// Simple yes/no confirmation for consequential actions.
Future<bool> confirmAction(BuildContext context, {required String title, required String body, required String confirmLabel, bool destructive = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.s.t('رجوع', 'Go back'))),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: WColors.error, foregroundColor: Colors.white) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r ?? false;
}
