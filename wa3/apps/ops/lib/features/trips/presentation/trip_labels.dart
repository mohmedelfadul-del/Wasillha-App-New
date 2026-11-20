import 'package:wa3_core/wa3_core.dart';

/// Staff-facing state names (the shared copy addresses the rider).
String opsStateLabel(S s, TripState st) => switch (st) {
      TripState.searching => s.t('يبحث عن سائقين', 'Searching for drivers'),
      TripState.offering => s.t('عروض واردة', 'Receiving offers'),
      TripState.driverEnRoute => s.t('السائق في الطريق للراكب', 'Driver en route to pickup'),
      TripState.arrived => s.t('وصلت الوجهة', 'Arrived at destination'),
      TripState.paymentPending => s.t('بانتظار الدفع النقدي', 'Awaiting cash payment'),
      _ => s.state(st),
    };

Tone stateTone(TripState st) => switch (st) {
      TripState.completed => Tone.success,
      TripState.cancelled => Tone.neutral,
      TripState.disputed => Tone.warning,
      _ => Tone.info,
    };
