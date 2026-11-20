import 'package:wa3_core/wa3_core.dart';

import '../../../app/widgets/fields.dart';
import '../domain/kyc_repository.dart';

Tone reviewTone(ReviewStatus r) => switch (r) {
      ReviewStatus.pending => Tone.info,
      ReviewStatus.approved => Tone.success,
      ReviewStatus.rejected => Tone.error,
      ReviewStatus.changesRequested => Tone.warning,
    };

/// Staff-facing document names (the shared copy addresses the driver).
String docTypeLabel(S s, DocumentType d) => d == DocumentType.driver_photo ? s.t('صورة السائق', 'Driver photo') : s.docType(d);

String claimLabel(S s, ClaimState c, String? holder) => switch (c) {
      ClaimState.unclaimed => s.t('غير محجوز', 'Unclaimed'),
      ClaimState.mine => s.t('محجوز لك', 'Claimed by you'),
      ClaimState.other => s.t('محجوز لدى ', 'Claimed by ') + ltr(shortId(holder ?? '')),
      ClaimState.decided => s.t('تم القرار', 'Decided'),
    };

Tone claimTone(ClaimState c) => switch (c) {
      ClaimState.unclaimed => Tone.neutral,
      ClaimState.mine => Tone.info,
      ClaimState.other => Tone.warning,
      ClaimState.decided => Tone.success,
    };

String whoLabel(S s, String? uid, String me) => uid == null ? '—' : uid == me ? s.t('أنت', 'You') : ltr(uid);
