import 'package:wa3_core/wa3_core.dart';

enum NoticeKind { documentApproved, documentRejected, documentChanges, tripCompleted, tripCancelled, riderRated }

/// One in-app notice derived from data the app already reads (no push).
class Notice {
  const Notice({required this.kind, required this.at, this.document, this.trip});
  final NoticeKind kind;
  final DateTime at;
  final ReviewDocument? document;
  final Trip? trip;
}

/// Document decisions and trip outcomes, newest first.
List<Notice> buildNotices({required List<ReviewDocument> documents, required List<Trip> trips}) {
  final out = <Notice>[];
  for (final d in documents) {
    final at = d.decidedAt;
    if (at == null) continue;
    final kind = switch (d.status) {
      ReviewStatus.approved => NoticeKind.documentApproved,
      ReviewStatus.rejected => NoticeKind.documentRejected,
      ReviewStatus.changesRequested => NoticeKind.documentChanges,
      ReviewStatus.pending => null,
    };
    if (kind != null) out.add(Notice(kind: kind, at: at, document: d));
  }
  for (final t in trips) {
    final done = t.stamp(TripState.completed);
    if (done != null) out.add(Notice(kind: NoticeKind.tripCompleted, at: done, trip: t));
    if (t.state == TripState.cancelled) {
      out.add(Notice(kind: NoticeKind.tripCancelled, at: t.cancellation?.at ?? t.stamp(TripState.cancelled) ?? t.createdAt, trip: t));
    }
    if (t.riderRating != null && done != null) {
      out.add(Notice(kind: NoticeKind.riderRated, at: done.add(const Duration(seconds: 1)), trip: t));
    }
  }
  out.sort((a, b) => b.at.compareTo(a.at));
  return out;
}
