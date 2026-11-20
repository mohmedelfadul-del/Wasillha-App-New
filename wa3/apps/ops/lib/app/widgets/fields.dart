import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// Label/value line that wraps instead of overflowing at 320 px / 200 % text.
class Field extends StatelessWidget {
  const Field(this.label, this.value, {super.key, this.selectable = false});
  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(spacing: 8, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('$label:', style: t.bodyMedium?.copyWith(color: muted)),
        selectable ? SelectableText(value, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)) : Text(value, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Section title inside a page.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(top: 16, bottom: 8),
        child: Semantics(header: true, child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
      );
}

/// Constrains page content width on wide screens.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = 960});
  final List<Widget> children;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      );
}

/// Short id for display (first 8 characters), full id in semantics/tooltip.
String shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);

/// "2026-11-20 14:03" (local time), bidi-isolated.
String dateTime(DateTime t) {
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return ltr('${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}');
}
