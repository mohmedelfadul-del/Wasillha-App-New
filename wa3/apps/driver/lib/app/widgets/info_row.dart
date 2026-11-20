import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// Label above value; wraps freely at large text sizes.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.emphasis = false});
  final String label;
  final String value;
  final bool emphasis;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WSpace.xs),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value, style: emphasis ? t.titleLarge : t.titleMedium),
      ]),
    );
  }
}

/// A plain bordered section with an optional title.
class Section extends StatelessWidget {
  const Section({super.key, this.title, required this.children});
  final String? title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(WSpace.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (title != null) ...[Text(title!, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: WSpace.sm)],
            ...children,
          ]),
        ),
      );
}
