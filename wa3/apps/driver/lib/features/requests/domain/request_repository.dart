import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';

abstract class RequestRepository {
  /// inbox/{uid}/requests: server-sanitized cards within the nearby radius.
  Stream<Live<List<RequestCard>>> watchInbox(String uid);

  /// trips/{tripId}/offers/{uid}: this driver's own offer, if any.
  Stream<Offer?> watchMyOffer({required String tripId, required String uid});

  /// Returns when the offer expires (server time).
  Future<DateTime> submitOffer({required String tripId, required int price, required int etaMinutes, required IntentKey key});
}
