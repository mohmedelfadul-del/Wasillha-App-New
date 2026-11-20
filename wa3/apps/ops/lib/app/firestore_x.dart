import 'package:cloud_firestore/cloud_firestore.dart';

import 'data_errors.dart';
import 'live.dart';

typedef Json = Map<String, dynamic>;

extension LiveQuery on Query<Json> {
  /// Realtime list including cache metadata, errors mapped to ApiFailure.
  Stream<Live<List<T>>> live<T>(T Function(DocumentSnapshot<Json> d) map) => snapshots(includeMetadataChanges: true)
      .map((s) => Live(s.docs.map(map).toList(), fromCache: s.metadata.isFromCache))
      .mapFailures();
}

extension LiveDoc on DocumentReference<Json> {
  Stream<Live<T?>> live<T>(T Function(DocumentSnapshot<Json> d) map) => snapshots(includeMetadataChanges: true)
      .map((s) => Live(s.exists ? map(s) : null, fromCache: s.metadata.isFromCache))
      .mapFailures();
}

DateTime? millisToDate(Object? v) {
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  if (v is Timestamp) return v.toDate();
  return null;
}
