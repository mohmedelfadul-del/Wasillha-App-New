import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';
import '../../../app/widgets/failure.dart';
import '../../../app/widgets/live_view.dart';
import '../../../app/widgets/now_builder.dart';
import '../../auth/application/session_controller.dart';
import '../domain/kyc_repository.dart';
import 'kyc_file_preview.dart';
import 'kyc_review_panel.dart';

/// One review item, rendered from its realtime document.
class KycDetailScreen extends StatelessWidget {
  const KycDetailScreen({super.key, required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final repo = context.services.kyc;
    if (!reviewPathPattern.hasMatch(path)) {
      return WStateView.empty(icon: Icons.search_off, title: s.t('رابط وثيقة غير صالح', 'Invalid document link'));
    }
    return LiveView<ReviewDocument?>(
      key: ValueKey(path),
      open: () => repo.watch(path),
      isEmpty: (d) => d == null,
      empty: (_) => WStateView.empty(icon: Icons.search_off, title: s.t('الوثيقة غير موجودة', 'Document not found')),
      builder: (context, doc) => _Loaded(doc: doc!),
    );
  }
}

class _Loaded extends StatefulWidget {
  const _Loaded({required this.doc});
  final ReviewDocument doc;
  @override
  State<_Loaded> createState() => _LoadedState();
}

class _LoadedState extends State<_Loaded> {
  Future<ReviewSubject>? _subject;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subject ??= context.services.kyc.subject(widget.doc);
  }

  Future<void> _claim() async {
    try {
      await context.services.kyc.claim(widget.doc.path, IntentKey.generate());
    } catch (e) {
      if (mounted) showOpsFailure(context, e, myUid: context.myUid);
    }
  }

  Future<void> _decide(Decision d, String? reason) async {
    final s = context.s;
    try {
      await context.services.kyc.decide(widget.doc.path, d, reason, IntentKey.generate());
      if (mounted) showSuccess(context, s.t('تم تسجيل القرار: ', 'Decision recorded: ') + s.review(ReviewStatus.parse(d.name)));
    } catch (e) {
      if (mounted) showOpsFailure(context, e, myUid: context.myUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReviewSubject>(
      future: _subject,
      builder: (context, snap) => NowBuilder(
        builder: (context, now) => KycReviewPanel(
          doc: widget.doc,
          now: now,
          subject: snap.data,
          onClaim: _claim,
          onDecide: _decide,
          filePreview: KycFilePreview(key: ValueKey(widget.doc.storagePath), storagePath: widget.doc.storagePath),
        ),
      ),
    );
  }
}
