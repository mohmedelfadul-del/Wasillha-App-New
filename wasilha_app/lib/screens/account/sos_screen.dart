import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/w_icon.dart';
import 'account_common.dart';

const _danger = Color(0xFFE4452E);

/// Sudan police emergency number.
const _emergencyNumber = '999';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with TickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..addStatusListener(_onHoldStatus);
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  bool _holding = false;
  bool _dispatched = false;

  @override
  void dispose() {
    _hold.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _onHoldStatus(AnimationStatus st) {
    if (st == AnimationStatus.completed && !_dispatched) {
      HapticFeedback.heavyImpact();
      setState(() {
        _dispatched = true;
        _holding = false;
      });
      _call(_emergencyNumber);
      _showAlerted();
    }
  }

  void _down() {
    if (_dispatched) return;
    HapticFeedback.selectionClick();
    setState(() => _holding = true);
    _hold.forward();
  }

  void _up() {
    if (_dispatched) return;
    setState(() => _holding = false);
    _hold.animateBack(0, duration: const Duration(milliseconds: 250));
  }

  Future<void> _call(String number) async {
    final s = context.read<AppState>();
    try {
      final ok = await launchUrl(Uri.parse('tel:$number'));
      if (!ok && mounted) snack(context, s.t('Call $number from your phone', 'اتصل بالرقم $number من هاتفك'));
    } catch (_) {
      if (mounted) snack(context, s.t('Call $number from your phone', 'اتصل بالرقم $number من هاتفك'));
    }
  }

  void _showAlerted() {
    final s = context.read<AppState>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF16100F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: _danger, shape: BoxShape.circle),
              child: const WIcon('shield', size: 24, strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(s.t('● SAFETY TEAM ALERTED', '● تم تنبيه فريق الأمان'),
                style: W.mono(size: 10, color: _danger, letterSpacing: 0.3)),
            const SizedBox(height: 8),
            Text(s.t('Help is on the way.', 'المساعدة في الطريق.'),
                style: s.ar ? W.arSerif(size: 30, color: Colors.white) : W.serif(size: 34, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              s.t('Our 24/7 team has your live location and trip details. We are also connecting you to police ($_emergencyNumber).',
                  'فريقنا يعمل على مدار الساعة ولديه موقعك وتفاصيل رحلتك. نقوم أيضًا بتوصيلك بالشرطة ($_emergencyNumber).'),
              style: W.sans(size: 13.5, color: const Color(0xA6FFFFFF), height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: _DarkBtn(
                  label: s.t('Call $_emergencyNumber again', 'اتصل بـ $_emergencyNumber مجددًا'),
                  color: _danger,
                  onTap: () => _call(_emergencyNumber),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DarkBtn(
                  label: s.t("I'm safe now", 'أنا بأمان الآن'),
                  color: const Color(0x1AFFFFFF),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() => _dispatched = false);
                    _hold.value = 0;
                  },
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _shareRide() async {
    final s = context.read<AppState>();
    final id = s.activeTripId ?? 'live';
    final link = 'https://wasilha.app/t/$id';
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) snack(context, s.t('Live ride link copied: $link', 'تم نسخ رابط الرحلة المباشر: $link'));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final label = _dispatched
        ? s.t('DISPATCHING…', 'جارٍ التواصل…')
        : _holding
            ? s.t('RELEASE TO CANCEL', 'اتركه للإلغاء')
            : s.t('HOLD TO CALL', 'اضغط مطولاً');
    return Scaffold(
      backgroundColor: W.text,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A0C0C), Color(0xFF0A0908)]),
        ),
        child: Stack(children: [
          // danger glow
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, -10),
                child: Center(
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [_danger.withValues(alpha: 0.19), _danger.withValues(alpha: 0)], stops: const [0, 0.6]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                AccountHeader(title: s.t('SAFETY · الأمان', 'الأمان · SAFETY'), dark: true, leadingIcon: 'close'),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 24, 18, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.t('● SAFETY MODE', '● وضع الأمان'), style: W.mono(size: 10, color: _danger, letterSpacing: 0.32)),
                    const SizedBox(height: 10),
                    SerifHeadline(s.t('You are not ', 'لست '), s.t('alone.', 'وحدك.'),
                        size: 46, color: Colors.white, accentColor: _danger),
                    const SizedBox(height: 8),
                    Text(s.t('Hold for 3 seconds to dispatch our safety team.', 'اضغط مع الاستمرار ٣ ثوانٍ لاستدعاء فريق الأمان.'),
                        style: W.sans(size: 13.5, color: const Color(0xA6FFFFFF))),
                  ]),
                ),
                const SizedBox(height: 40),
                Center(
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(alignment: Alignment.center, children: [
                      // pulse ring
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, _) {
                          final v = _pulse.value;
                          return Transform.scale(
                            scale: 1 + v * 0.3,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: _danger.withValues(alpha: 0.18 * (1 - v))),
                            ),
                          );
                        },
                      ),
                      Listener(
                        onPointerDown: (_) => _down(),
                        onPointerUp: (_) => _up(),
                        onPointerCancel: (_) => _up(),
                        child: AnimatedScale(
                          scale: _holding ? 0.98 : 1,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: _danger,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: _danger.withValues(alpha: 0.19), spreadRadius: 8),
                                BoxShadow(color: _danger.withValues(alpha: 0.31), blurRadius: 60, offset: const Offset(0, 24)),
                              ],
                            ),
                            child: AnimatedBuilder(
                              animation: _hold,
                              builder: (_, _) => CustomPaint(
                                painter: _RingPainter(_dispatched ? 1 : _hold.value),
                                child: Center(
                                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                                    Text('SOS', style: W.serif(size: 52, color: Colors.white, letterSpacing: 0.08 * 52)),
                                    const SizedBox(height: 4),
                                    Text(label, style: W.mono(size: 10, color: const Color(0xB3FFFFFF), letterSpacing: 0.24)),
                                    if (_holding && !_dispatched) ...[
                                      const SizedBox(height: 4),
                                      Text('${(3 - _hold.value * 3).ceil()}',
                                          style: W.mono(size: 12, color: Colors.white, weight: FontWeight.w600, letterSpacing: 0)),
                                    ],
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 28, 18, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.t('QUICK DISPATCH', 'تواصل سريع'), style: W.mono(size: 9.5, color: const Color(0x80FFFFFF), letterSpacing: 0.3)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _QuickTile(icon: 'shield', label: s.t('Traffic police', 'شرطة المرور'), number: '777', onTap: () => _call('777'))),
                      const SizedBox(width: 8),
                      Expanded(child: _QuickTile(icon: 'plus', label: s.t('Medical', 'الإسعاف'), number: '333', onTap: () => _call('333'))),
                      const SizedBox(width: 8),
                      Expanded(child: _QuickTile(icon: 'user', label: s.t('Women support', 'دعم المرأة'), number: '188', onTap: () => _call('188'))),
                    ]),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 20, 18, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x0FFFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x14FFFFFF), width: 0.5),
                    ),
                    child: Column(children: [
                      _DarkRow(
                        icon: 'user',
                        title: s.t('Call a trusted contact', 'اتصال بأحد المعارف'),
                        detail: s.t('Trusted contacts', 'جهات الاتصال الموثوقة'),
                        onTap: () => snack(context, s.t('Trusted contacts — coming soon', 'جهات الاتصال الموثوقة — قريبًا')),
                      ),
                      _DarkRow(
                        icon: 'eye',
                        title: s.t('Share my ride live', 'شارك رحلتي مباشرة'),
                        detail: s.t('Live tracking link', 'بث مباشر'),
                        onTap: _shareRide,
                      ),
                      _DarkRow(
                        icon: 'help',
                        title: s.t('Report a problem', 'الإبلاغ عن مشكلة'),
                        detail: s.t('24/7 support · police $_emergencyNumber', 'دعم ٢٤/٧ · الشرطة $_emergencyNumber'),
                        onTap: () => _call(_emergencyNumber),
                        last: true,
                      ),
                    ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 30, 18, 0),
                  child: Text(
                    s.t('WASILHA SAFETY · 24/7 RESPONSE\nYOUR LOCATION IS SHARED ON ACTIVATION',
                        'WASILHA SAFETY · فريق متخصص ٢٤/٧\nموقعك يُشارك تلقائيًا عند تفعيل SOS'),
                    textAlign: TextAlign.center,
                    style: W.mono(size: 10, color: const Color(0x66FFFFFF), letterSpacing: 0.24).copyWith(height: 1.7),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 8;
    final c = size.center(Offset.zero);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0x26FFFFFF);
    canvas.drawCircle(c, r, track);
    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.label, required this.number, required this.onTap});
  final String icon;
  final String label;
  final String number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x14FFFFFF), width: 0.5),
          ),
          child: Column(children: [
            WIcon(icon, size: 18, strokeWidth: 1.7, color: Colors.white),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: W.sans(size: 11, weight: FontWeight.w500, color: Colors.white)),
            const SizedBox(height: 4),
            Text(number, style: W.mono(size: 10, color: const Color(0x80FFFFFF), letterSpacing: 0)),
          ]),
        ),
      );
}

class _DarkRow extends StatelessWidget {
  const _DarkRow({required this.icon, required this.title, required this.detail, required this.onTap, this.last = false});
  final String icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: last ? null : const Border(bottom: BorderSide(color: Color(0x0FFFFFFF), width: 0.5)),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(10)),
              child: WIcon(icon, size: 16, strokeWidth: 1.7, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: W.sans(size: 14, weight: FontWeight.w500, color: Colors.white)),
                const SizedBox(height: 2),
                Text(detail, style: W.sans(size: 11.5, color: const Color(0x80FFFFFF))),
              ]),
            ),
            const WIcon('chevron', size: 14, color: Color(0x80FFFFFF)),
          ]),
        ),
      );
}

class _DarkBtn extends StatelessWidget {
  const _DarkBtn({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: W.sans(size: 14, weight: FontWeight.w500, color: Colors.white)),
        ),
      );
}
