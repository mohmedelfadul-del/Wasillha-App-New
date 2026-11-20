import 'package:wa3_core/wa3_core.dart';

/// The driver's one primary action per trip state. The wire command name is
/// the enum name.
enum StageCommand { markArrived, startTrip, finishTrip, recordCash }

StageCommand? stageCommandFor(TripState s) => switch (s) {
      TripState.driverEnRoute => StageCommand.markArrived,
      TripState.driverArrived => StageCommand.startTrip,
      TripState.inProgress => StageCommand.finishTrip,
      TripState.paymentPending => StageCommand.recordCash,
      _ => null,
    };

String stageLabel(S s, StageCommand c) => switch (c) {
      StageCommand.markArrived => s.t('وصلت', 'Arrived'),
      StageCommand.startTrip => s.t('ابدأ الرحلة', 'Start trip'),
      StageCommand.finishTrip => s.t('إنهاء', 'Finish'),
      StageCommand.recordCash => s.t('تسجيل المبلغ النقدي', 'Record cash'),
    };

/// Driver-facing title for each state (the shared strings are rider-facing).
String driverStageTitle(S s, TripState st) => switch (st) {
      TripState.driverAssigned => s.t('جارٍ تأكيد الرحلة…', 'Confirming the trip…'),
      TripState.driverEnRoute => s.t('توجّه إلى نقطة الالتقاء', 'Drive to pickup'),
      TripState.driverArrived => s.t('بانتظار الراكب', 'Waiting for the rider'),
      TripState.inProgress => s.t('في الطريق إلى الوجهة', 'Driving to destination'),
      TripState.arrived => s.t('جارٍ إصدار الإيصال…', 'Preparing the receipt…'),
      TripState.paymentPending => s.t('استلم المبلغ نقداً', 'Collect cash'),
      TripState.completed => s.t('اكتملت الرحلة', 'Trip completed'),
      TripState.cancelled => s.t('أُلغيت الرحلة', 'Trip cancelled'),
      TripState.disputed => s.t('الرحلة محل اعتراض', 'Trip disputed'),
      _ => s.state(st),
    };

/// Driver may cancel only after assignment and before pickup (server rule).
bool driverCanCancel(TripState s) => s == TripState.driverAssigned || s == TripState.driverEnRoute || s == TripState.driverArrived;

/// Where navigation goes: pickup before the rider boards, destination after.
bool navigatesToPickup(TripState s) => s.index <= TripState.driverArrived.index;
