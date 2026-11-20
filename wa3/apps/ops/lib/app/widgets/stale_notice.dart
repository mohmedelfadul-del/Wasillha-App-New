import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// Shows "may be out of date" when data has come from the cache for more
/// than a few seconds (brief rule 3).
class StaleNotice extends StatefulWidget {
  const StaleNotice({super.key, required this.fromCache, this.after = const Duration(seconds: 3)});
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
    _arm();
  }

  @override
  void didUpdateWidget(StaleNotice old) {
    super.didUpdateWidget(old);
    if (old.fromCache != widget.fromCache) _arm();
  }

  void _arm() {
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
      _show && widget.fromCache ? WBanner(tone: Tone.warning, text: context.s.staleData) : const SizedBox.shrink();
}
