import 'dart:async';

import 'package:flutter/material.dart';

import '../services.dart';

/// Rebuilds every [every] so ages ("waiting 12 min") stay current.
class NowBuilder extends StatefulWidget {
  const NowBuilder({super.key, required this.builder, this.every = const Duration(seconds: 30)});
  final Widget Function(BuildContext context, DateTime now) builder;
  final Duration every;
  @override
  State<NowBuilder> createState() => _NowBuilderState();
}

class _NowBuilderState extends State<NowBuilder> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(widget.every, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, context.services.now());
}
