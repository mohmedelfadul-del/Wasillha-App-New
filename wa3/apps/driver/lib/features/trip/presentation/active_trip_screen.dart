import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';
import '../../../app/widgets/stale_notice.dart';
import '../../location/domain/location_port.dart';
import '../application/active_trip_controller.dart';
import '../domain/stage_action.dart';
import 'cash_sheet.dart';
import 'trip_details.dart';
import 'trip_finished_view.dart';

/// The assigned trip, rendered from trips/{id}. ONE primary action that
/// changes with the stage; navigation handoff, call and pre-pickup cancel.
class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({super.key, required this.tripId, required this.onDone});
  final String tripId;

  /// Back to work once the trip is over (completed or cancelled).
  final VoidCallback onDone;
  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  late final ActiveTripController _c = ActiveTripController(repo: context.services.trips, tripId: widget.tripId);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    final s = context.s;
    final r = await confirmWithReason(
      context,
      title: s.t('إلغاء الرحلة قبل الركوب', 'Cancel before pickup'),
      reasons: [for (final code in cancelReasons['driver']!) (code, s.cancelReason(code))],
      confirmLabel: s.t('ألغِ الرحلة', 'Cancel trip'),
    );
    if (r == null || !mounted) return;
    try {
      await _c.cancel(r.reason, r.note);
    } on ApiFailure catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Future<void> _primary(StageCommand cmd, Trip t) async {
    if (cmd == StageCommand.recordCash) {
      // Not awaited: the stage button shouldn't spin while the sheet is open.
      unawaited(showCashSheet(context, trip: t, onRecord: _c.recordCash));
      return;
    }
    await _c.runStage(cmd);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final t = _c.trip;
        if (_c.loadError != null) {
          return Scaffold(appBar: AppBar(title: Text(s.t('الرحلة', 'Trip'))), body: WStateView.error(context, _c.loadError!));
        }
        if (_c.loading) return Scaffold(body: WStateView.loading());
        if (t == null) {
          return Scaffold(
            appBar: AppBar(title: Text(s.t('الرحلة', 'Trip'))),
            body: WStateView.empty(
              icon: Icons.search_off,
              title: s.t('لم نجد هذه الرحلة', 'We can’t find this trip'),
              body: s.t('ربما أُلغيت أو لم تعد مسندة إليك.', 'It may have been cancelled or is no longer assigned to you.'),
              actionLabel: s.t('العودة إلى العمل', 'Back to work'),
              onAction: widget.onDone,
            ),
          );
        }
        if (t.state.isTerminal) return TripFinishedView(trip: t, controller: _c, onDone: widget.onDone, fromCache: _c.live!.fromCache);
        final cmd = stageCommandFor(t.state);
        return Scaffold(
          appBar: AppBar(title: Text(driverStageTitle(s, t.state)), automaticallyImplyLeading: false),
          body: ListView(padding: const EdgeInsets.all(WSpace.lg), children: [
            StaleNotice(fromCache: _c.live!.fromCache),
            const _LocationNotice(),
            if (_c.ackError != null)
              WBanner(tone: Tone.error, text: s.error(_c.ackError!.code, _c.ackError!.message), actionLabel: s.retry, onAction: _c.retryAck),
            if (t.locationStale)
              WBanner(tone: Tone.warning, text: s.t('الراكب يرى موقعك قديماً. تأكد أن الموقع مفعّل.', 'The rider sees your location as out of date. Check that location is on.')),
            TripDetails(trip: t),
            if (driverCanCancel(t.state)) ...[
              const SizedBox(height: WSpace.lg),
              TextButton.icon(
                onPressed: _cancel,
                icon: const Icon(Icons.cancel_outlined, color: WColors.error),
                label: Text(s.t('إلغاء الرحلة', 'Cancel trip'), style: const TextStyle(color: WColors.error)),
              ),
            ],
          ]),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(WSpace.lg),
              child: cmd == null
                  ? _Waiting(state: t.state, acking: _c.acking)
                  : PrimaryAction(key: ValueKey(cmd), label: stageLabel(s, cmd), large: true, onPressed: () => _primary(cmd, t)),
            ),
          ),
        );
      },
    );
  }
}

/// States without a driver action (acknowledging, receipt being issued).
class _Waiting extends StatelessWidget {
  const _Waiting({required this.state, required this.acking});
  final TripState state;
  final bool acking;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
      const SizedBox(width: WSpace.md),
      Flexible(child: Text(driverStageTitle(s, state), textAlign: TextAlign.center)),
    ]);
  }
}

/// The rider follows the driver's position: say so when it isn't being sent.
class _LocationNotice extends StatelessWidget {
  const _LocationNotice();
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final loc = context.services.location;
    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        if (loc.access != null && loc.access != LocationAccess.granted) {
          return WBanner(
            tone: Tone.error,
            text: s.t('موقعك لا يُرسل: إذن الموقع مغلق. الراكب لا يرى وصولك.', 'Your location isn’t being sent: location permission is off. The rider can’t see you coming.'),
            actionLabel: s.t('اسمح', 'Allow'),
            onAction: () => loc.access == LocationAccess.denied ? loc.requestAccess() : loc.source.openAppSettings(),
          );
        }
        if (loc.running && loc.writeFailing) {
          return WBanner(tone: Tone.warning, text: s.t('تعذّر إرسال موقعك الآن. سنعيد المحاولة تلقائياً.', 'We can’t send your location right now. We’ll keep retrying.'));
        }
        return const SizedBox.shrink();
      },
    );
  }
}
