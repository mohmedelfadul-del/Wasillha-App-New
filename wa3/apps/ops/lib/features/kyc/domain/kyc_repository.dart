import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';

/// Server claim lifetime (ops.ts CLAIM_TTL_MS).
const claimTtl = Duration(minutes: 15);

/// Same shape the server accepts (ops.ts REVIEW_PATH).
final reviewPathPattern = RegExp(r'^(drivers|vehicles)/[A-Za-z0-9_-]+/documents/[a-z_]+$');

enum ClaimState { unclaimed, mine, other, decided }

/// How the item stands for me right now. An expired claim by someone else
/// counts as unclaimed, as the server treats it.
ClaimState claimStateOf(ReviewDocument d, String myUid, DateTime now) {
  if (d.status != ReviewStatus.pending) return ClaimState.decided;
  final holder = d.claimedBy;
  if (holder == null || holder.isEmpty) return ClaimState.unclaimed;
  if (holder == myUid) return ClaimState.mine;
  final at = d.claimedAt;
  if (at != null && now.difference(at) >= claimTtl) return ClaimState.unclaimed;
  return ClaimState.other;
}

/// Who the document belongs to.
class ReviewSubject {
  const ReviewSubject({required this.driverName, this.driverPhone, this.vehicleTitle, this.plate});
  final String driverName;
  final String? driverPhone;
  final String? vehicleTitle;
  final String? plate;
}

enum Decision { approved, rejected, changesRequested }

/// Rejecting or requesting changes requires a reason (server: decideReview).
bool decisionNeedsReason(Decision d) => d != Decision.approved;

abstract class KycRepository {
  /// Pending documents, oldest submission first.
  Stream<Live<List<ReviewDocument>>> pending({int limit = 100});
  Stream<Live<ReviewDocument?>> watch(String path);
  Future<ReviewSubject> subject(ReviewDocument d);
  Future<String> downloadUrl(String storagePath);
  Future<void> claim(String path, IntentKey key);
  Future<void> decide(String path, Decision decision, String? reason, IntentKey key);
}
