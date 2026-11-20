import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../live.dart';
import 'failure.dart';
import 'stale_notice.dart';

/// Renders a realtime read with every non-content state designed:
/// loading, empty, error + retry, offline, permission denied, stale.
/// Give it a new [Key] when the query changes.
class LiveView<T> extends StatefulWidget {
  const LiveView({super.key, required this.open, required this.builder, this.isEmpty, this.empty});
  final Stream<Live<T>> Function() open;
  final Widget Function(BuildContext context, T value) builder;
  final bool Function(T value)? isEmpty;
  final Widget Function(BuildContext context)? empty;

  @override
  State<LiveView<T>> createState() => _LiveViewState<T>();
}

class _LiveViewState<T> extends State<LiveView<T>> {
  late Stream<Live<T>> _stream = widget.open();

  void _retry() => setState(() => _stream = widget.open());

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Live<T>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) return opsErrorView(context, snap.error!, onRetry: _retry);
        final live = snap.data;
        if (live == null) return WStateView.loading(label: context.s.loading);
        final empty = widget.isEmpty?.call(live.value) ?? false;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          StaleNotice(fromCache: live.fromCache),
          Expanded(child: empty && widget.empty != null ? widget.empty!(context) : widget.builder(context, live.value)),
        ]);
      },
    );
  }
}

/// Inline variant for a section inside a scrolling page: shrink-wraps its
/// states instead of filling the screen.
class LiveSection<T> extends StatefulWidget {
  const LiveSection({super.key, required this.open, required this.builder, this.isEmpty, this.emptyText});
  final Stream<Live<T>> Function() open;
  final Widget Function(BuildContext context, T value) builder;
  final bool Function(T value)? isEmpty;
  final String? emptyText;

  @override
  State<LiveSection<T>> createState() => _LiveSectionState<T>();
}

class _LiveSectionState<T> extends State<LiveSection<T>> {
  late Stream<Live<T>> _stream = widget.open();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return StreamBuilder<Live<T>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          final e = snap.error;
          final f = e is ApiFailure ? e : ApiFailure('internal', '$e');
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            WBanner(tone: Tone.error, text: describeFailure(s, f)),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(onPressed: () => setState(() => _stream = widget.open()), child: Text(s.retry)),
            ),
          ]);
        }
        final live = snap.data;
        if (live == null) return Padding(padding: const EdgeInsets.all(WSpace.md), child: Semantics(label: s.loading, child: const LinearProgressIndicator()));
        final empty = widget.isEmpty?.call(live.value) ?? false;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          StaleNotice(fromCache: live.fromCache),
          if (empty)
            Padding(padding: const EdgeInsets.symmetric(vertical: WSpace.sm), child: Text(widget.emptyText ?? '—'))
          else
            widget.builder(context, live.value),
        ]);
      },
    );
  }
}
