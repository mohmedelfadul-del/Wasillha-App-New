import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';
import '../../trip/presentation/cancel_flow.dart';
import 'safety_sheet.dart';

/// Bottom actions within thumb reach: call, share, safety, and pre-pickup cancel.
class TripActions extends StatefulWidget {
  const TripActions({super.key, required this.trip});
  final Trip trip;
  @override
  State<TripActions> createState() => _TripActionsState();
}

class _TripActionsState extends State<TripActions> {
  bool _sharing = false;

  Future<void> _call(String phone) async {
    final s = context.s;
    final ok = await launchUrl(Uri(scheme: 'tel', path: phone)).catchError((_) => false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${s.t('تعذّر فتح تطبيق الهاتف. رقم السائق:', 'Couldn’t open the phone app. Driver’s number:')} ${ltr(phone)}')));
    }
  }

  Future<void> _share() async {
    final s = context.s;
    setState(() => _sharing = true);
    try {
      final link = await context.deps.trips.shareLink(tripId: widget.trip.id, key: IntentKey.generate());
      await SharePlus.instance.share(
        ShareParams(text: '${s.t('تابع رحلتي مباشرة على وصلها', 'Follow my Wasilha trip live')}: $link', subject: s.t('رحلتي على وصلها', 'My Wasilha trip')),
      );
    } on ApiFailure catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = widget.trip;
    final phone = t.driver?.phone;
    final stack = MediaQuery.textScalerOf(context).scale(14) > 20 || MediaQuery.sizeOf(context).width < 360;
    final buttons = <Widget>[
      if (phone != null && phone.isNotEmpty)
        FilledButton.icon(onPressed: () => _call(phone), icon: const Icon(Icons.phone), label: Text(s.t('اتصل بالسائق', 'Call driver'))),
      OutlinedButton.icon(
        onPressed: _sharing ? null : _share,
        icon: _sharing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.share_outlined),
        label: Text(s.t('شارك الرحلة', 'Share trip')),
      ),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: WColors.error),
        onPressed: () => showSafetySheet(context, t),
        icon: const Icon(Icons.shield_outlined),
        label: Text(s.t('بلاغ سلامة', 'Safety')),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(WSpace.lg, WSpace.sm, WSpace.lg, WSpace.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stack)
            for (final b in buttons)
              Padding(
                padding: const EdgeInsets.only(bottom: WSpace.sm),
                child: b,
              )
          else
            Row(
              children: [
                for (var i = 0; i < buttons.length; i++) ...[if (i > 0) const SizedBox(width: WSpace.sm), Expanded(child: buttons[i])],
              ],
            ),
          if (t.state.isPrePickup) TextButton(onPressed: () => cancelTripWithReason(context, t), child: Text(s.t('إلغاء الرحلة', 'Cancel trip'))),
        ],
      ),
    );
  }
}
