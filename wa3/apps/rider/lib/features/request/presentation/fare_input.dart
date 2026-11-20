import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../common/presentation/digits.dart';

/// Whole-unit fare limited to the server's quote, with a stepper and typing.
/// Reports null while the typed amount is outside the bounds or empty.
class FareInput extends StatefulWidget {
  const FareInput({super.key, required this.quote, required this.value, required this.onChanged});
  final Quote quote;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  State<FareInput> createState() => _FareInputState();
}

/// Validation message for a typed fare, or null when it is acceptable.
String? fareError(S s, Quote q, String text) {
  final v = int.tryParse(asciiDigits(text).trim());
  if (v == null) return s.t('اكتب المبلغ', 'Enter an amount');
  if (v < q.minFare) return '${s.t('أقل مبلغ مسموح', 'The lowest allowed is')} ${money(q.minFare, ar: s.ar)}';
  if (v > q.maxFare) return '${s.t('أعلى مبلغ مسموح', 'The highest allowed is')} ${money(q.maxFare, ar: s.ar)}';
  return null;
}

class _FareInputState extends State<FareInput> {
  late final TextEditingController _text = TextEditingController(text: widget.value?.toString() ?? '');
  String? _error;

  int get _step {
    final range = widget.quote.maxFare - widget.quote.minFare;
    if (range >= 1000) return 50;
    if (range >= 100) return 10;
    return 1;
  }

  @override
  void didUpdateWidget(FareInput old) {
    super.didUpdateWidget(old);
    final v = widget.value;
    if (v != null && v.toString() != _text.text) {
      _text.text = v.toString();
      _error = null;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _typed(String t) {
    final s = context.s;
    final err = fareError(s, widget.quote, t);
    setState(() => _error = err);
    widget.onChanged(err == null ? int.parse(t) : null);
  }

  void _bump(int dir) {
    final q = widget.quote;
    final cur = int.tryParse(_text.text) ?? q.referenceFare;
    final next = (cur + dir * _step).clamp(q.minFare, q.maxFare);
    _text.text = next.toString();
    setState(() => _error = null);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final q = widget.quote;
    final v = widget.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(s.t('السعر الذي تعرضه', 'Your price'), style: theme.textTheme.titleMedium),
      const SizedBox(height: WSpace.sm),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconButton.outlined(
          tooltip: s.t('خفّض السعر', 'Lower the price'),
          icon: const Icon(Icons.remove),
          onPressed: v != null && v > q.minFare ? () => _bump(-1) : null,
        ),
        const SizedBox(width: WSpace.sm),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              key: const Key('fare-field'),
              controller: _text,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
              inputFormatters: const [AsciiDigitsFormatter()],
              decoration: InputDecoration(suffixText: s.currency, errorText: _error, errorMaxLines: 3),
              onChanged: _typed,
            ),
          ),
        ),
        const SizedBox(width: WSpace.sm),
        IconButton.outlined(
          tooltip: s.t('ارفع السعر', 'Raise the price'),
          icon: const Icon(Icons.add),
          onPressed: v != null && v < q.maxFare ? () => _bump(1) : null,
        ),
      ]),
      const SizedBox(height: WSpace.sm),
      Text('${s.t('المسموح بين', 'Allowed between')} ${money(q.minFare, ar: s.ar)} ${s.t('و', 'and')} ${money(q.maxFare, ar: s.ar)}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      if (v != q.referenceFare)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: () {
              _text.text = q.referenceFare.toString();
              setState(() => _error = null);
              widget.onChanged(q.referenceFare);
            },
            child: Text('${s.t('استخدم السعر المقترح', 'Use the suggested price')} ${money(q.referenceFare, ar: s.ar)}'),
          ),
        ),
    ]);
  }
}
