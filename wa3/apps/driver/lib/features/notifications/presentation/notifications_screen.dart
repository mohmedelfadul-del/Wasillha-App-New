import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/format.dart';
import '../../../app/live.dart';
import '../../../app/services.dart';
import '../../history/domain/history_repository.dart';
import '../domain/notification_feed.dart';

/// In-app list of document decisions and trip events, derived from data the
/// app already reads. No push notifications in v1.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.uid});
  final String uid;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Stream<List<ReviewDocument>> _docs = _openDocs();
  late Future<TripPage> _trips = context.services.history.page(widget.uid);

  Stream<List<ReviewDocument>> _openDocs() {
    final d = context.services.documents;
    return combineLatest2(d.watchDriverDocuments(widget.uid), d.watchAllVehicleDocuments(widget.uid), (Live<Map<DocumentType, ReviewDocument>> a, List<ReviewDocument> b) => [...a.data.values, ...b]);
  }

  void _retry() => setState(() {
        _docs = _openDocs();
        _trips = context.services.history.page(widget.uid);
      });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('الإشعارات', 'Notifications'))),
      body: StreamBuilder<List<ReviewDocument>>(
        stream: _docs,
        builder: (context, docs) => FutureBuilder<TripPage>(
          future: _trips,
          builder: (context, trips) {
            final err = docs.error ?? trips.error;
            if (err != null) return WStateView.error(context, err, onRetry: _retry);
            if (!docs.hasData || !trips.hasData) return WStateView.loading();
            final items = buildNotices(documents: docs.data!, trips: trips.data!.trips);
            if (items.isEmpty) {
              return WStateView.empty(icon: Icons.notifications_none, title: s.t('لا إشعارات بعد', 'No notifications yet'), body: s.t('تظهر هنا قرارات وثائقك ونتائج رحلاتك.', 'Decisions on your documents and trip outcomes appear here.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(WSpace.lg),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, i) => NoticeTile(notice: items[i]),
            );
          },
        ),
      ),
    );
  }
}

class NoticeTile extends StatelessWidget {
  const NoticeTile({super.key, required this.notice});
  final Notice notice;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final n = notice;
    final doc = n.document;
    final (Tone tone, String title, String? body) = switch (n.kind) {
      NoticeKind.documentApproved => (Tone.success, '${s.docType(doc!.type)}: ${s.review(ReviewStatus.approved)}', null),
      NoticeKind.documentRejected => (Tone.error, '${s.docType(doc!.type)}: ${s.review(ReviewStatus.rejected)}', '${s.t('السبب', 'Reason')}: ${doc.reason ?? '—'} · ${s.t('ارفع صورة جديدة من الوثائق.', 'Upload a new photo from Documents.')}'),
      NoticeKind.documentChanges => (Tone.warning, '${s.docType(doc!.type)}: ${s.review(ReviewStatus.changesRequested)}', '${s.t('السبب', 'Reason')}: ${doc.reason ?? '—'}'),
      NoticeKind.tripCompleted => (Tone.success, s.t('اكتملت رحلة', 'Trip completed'), '${n.trip!.dropoff.label} · ${money(n.trip!.fare ?? 0, ar: s.ar)}'),
      NoticeKind.tripCancelled => (Tone.warning, s.t('أُلغيت رحلة', 'Trip cancelled'), s.cancelReason(n.trip!.cancellation?.reason ?? 'other')),
      NoticeKind.riderRated => (Tone.info, s.t('قيّمك راكب', 'A rider rated you'), '${ltr('${n.trip!.riderRating!.stars}')} / ${ltr('5')}'),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      StatusBadge(tone: tone, label: title),
      if (body != null) Padding(padding: const EdgeInsets.only(top: WSpace.xs), child: Text(body)),
      Text(dateTime(n.at), style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
