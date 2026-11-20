import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// "May be out of date" once data has come only from the cache for a few
/// seconds (brief rule 3).
class StaleNotice extends StatefulWidget {
  const StaleNotice({super.key, required this.fromCache, this.after = const Duration(seconds: 4)});
  final bool fromCache;
  final Duration after;
  @override
  State<StaleNotice> createState() => _StaleNoticeState();
}

class _StaleNoticeState extends State<StaleNotice> {
  Timer? _t;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(StaleNotice old) {
    super.didUpdateWidget(old);
    if (old.fromCache != widget.fromCache) _sync();
  }

  void _sync() {
    _t?.cancel();
    if (!widget.fromCache) {
      _show = false;
      return;
    }
    _t = Timer(widget.after, () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _show ? WBanner(tone: Tone.warning, text: '${context.s.staleData} · ${context.s.offlineTitle}') : const SizedBox.shrink();
}
