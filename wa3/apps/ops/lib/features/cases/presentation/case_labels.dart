import 'package:wa3_core/wa3_core.dart';

import '../../../app/widgets/fields.dart';

String caseTypeLabel(S s, CaseType t) => switch (t) {
      CaseType.dispute => s.t('اعتراض على رحلة', 'Trip dispute'),
      CaseType.safety => s.t('بلاغ سلامة', 'Safety report'),
      CaseType.support => s.t('طلب دعم', 'Support request'),
    };

String caseStatusLabel(S s, String st) => switch (st) {
      'open' => s.t('مفتوح', 'Open'),
      'inProgress' => s.t('قيد المعالجة', 'In progress'),
      'resolved' => s.t('مغلق', 'Resolved'),
      _ => st,
    };

Tone caseStatusTone(String st) => switch (st) {
      'open' => Tone.warning,
      'inProgress' => Tone.info,
      'resolved' => Tone.success,
      _ => Tone.neutral,
    };

String ownerLabel(S s, String? uid, String me) =>
    uid == null ? s.t('بلا مسؤول', 'Unowned') : uid == me ? s.t('أنت', 'You') : ltr(shortId(uid));
