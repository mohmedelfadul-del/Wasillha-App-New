import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../../../app/widgets/stale_notice.dart';
import '../../account/domain/driver_repository.dart';
import '../../requests/presentation/requests_section.dart';
import '../application/availability_controller.dart';
import 'online_messages.dart';
import 'status_panel.dart';
import 'today_card.dart';

/// The Work tab: availability (one large online/offline action), today's
/// summary, and nearby requests while online.
class AvailabilityScreen extends StatelessWidget {
  const AvailabilityScreen({super.key, required this.live, required this.controller});
  final Live<DriverState> live;
  final AvailabilityController controller;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final d = live.data;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('العمل', 'Work'))),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final online = d.profile.online;
          return ListView(
            padding: const EdgeInsets.all(WSpace.lg),
            children: [
              StaleNotice(fromCache: live.fromCache),
              if (d.locationLost)
                _gap(WBanner(
                  tone: Tone.warning,
                  text: s.t('أوقفنا اتصالك بالعمل لأن موقعك توقف عن الوصول إلينا. أبقِ الموقع مفعّلاً والتطبيق مفتوحاً ثم اتصل مجدداً.',
                      'You were taken offline because your location stopped reaching us. Keep location on and the app open, then go online again.'),
                )),
              if (controller.block != null) _gap(WBanner(tone: Tone.error, text: onlineFailureText(s, controller.block!, controller.failure))),
              if (online && controller.location.writeFailing)
                _gap(WBanner(
                  tone: Tone.warning,
                  text: s.t('تعذّر إرسال موقعك الآن. سنعيد المحاولة تلقائياً؛ قد لا تصلك طلبات حتى يعود الاتصال.',
                      'We can’t send your location right now. We’ll keep retrying; you may not get requests until it’s back.'),
                )),
              StatusPanel(driver: d, controller: controller),
              const SizedBox(height: WSpace.lg),
              TodayCard(uid: d.profile.uid),
              if (online) ...[const SizedBox(height: WSpace.xl), RequestsSection(uid: d.profile.uid)],
            ],
          );
        },
      ),
    );
  }

  Widget _gap(Widget w) => Padding(padding: const EdgeInsets.only(bottom: WSpace.md), child: w);
}
