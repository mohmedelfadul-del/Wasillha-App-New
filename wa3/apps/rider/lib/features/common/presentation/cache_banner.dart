import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// "May be out of date" banner, shown only when data has come from the local
/// cache for longer than [delay] (brief: realtime rule 3).
class CacheBanner extends StatefulWidget {
  const CacheBanner({super.key, required this.fromCache, this.delay = const Duration(seconds: 4)});
  final bool fromCache;
  final Duration delay;

  @override
  State<CacheBanner> createState() => _CacheBannerState();
}

class _CacheBannerState extends State<CacheBanner> {
  Timer? _timer;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(CacheBanner old) {
    super.didUpdateWidget(old);
    if (old.fromCache != widget.fromCache) _sync();
  }

  void _sync() {
    _timer?.cancel();
    if (!widget.fromCache) {
      _show = false;
      return;
    }
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _show ? WBanner(tone: Tone.warning, text: context.s.staleData) : const SizedBox.shrink();
}
