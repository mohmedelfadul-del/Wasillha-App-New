import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';
import 'account_common.dart';
import 'settings_appearance.dart';

String maskPhone(String phone) {
  final p = phone.replaceAll(' ', '');
  if (p.length < 8) return phone;
  final cc = p.startsWith('+249') ? '+249 ' : '';
  final rest = cc.isEmpty ? p : p.substring(4);
  if (rest.length < 6) return phone;
  return '$cc${rest.substring(0, 2)} *** ${rest.substring(rest.length - 4)}';
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final WasilhaBackend _backend = context.read<WasilhaBackend>();
  late final Stream<UserProfile?> _profile = _backend.profile();
  late final Stream<List<Place>> _places = _backend.savedPlaces();
  late final Stream<List<AppNotification>> _notes = _backend.notifications();
  bool _signingOut = false;

  Future<void> _editName(UserProfile? p) async {
    final s = context.read<AppState>();
    final ctrl = TextEditingController(text: p?.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(s.t('Your name', 'اسمك'), style: W.serif(size: 28)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          cursorColor: s.accent,
          style: W.sans(size: 16),
          decoration: InputDecoration(
            hintText: s.t('Full name', 'الاسم الكامل'),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: s.accent, width: 1.5)),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.t('Cancel', 'إلغاء'), style: W.sans(color: W.text2)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: Text(s.t('Save', 'حفظ'), style: W.sans(weight: FontWeight.w600, color: s.accent)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    final v = name?.trim();
    if (v == null || v.isEmpty || v == p?.name) return;
    try {
      await _backend.updateProfile(name: v);
      if (mounted) snack(context, s.t('Name updated', 'تم تحديث الاسم'));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _signOut() async {
    final s = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(s.t('Sign out?', 'تسجيل الخروج؟'), style: W.serif(size: 28)),
        content: Text(s.t('You can sign back in with your phone number.', 'يمكنك الدخول مجددًا برقم هاتفك.'), style: W.sans(color: W.text2)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(s.t('Cancel', 'إلغاء'), style: W.sans(color: W.text2))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.t('Sign out', 'خروج'), style: W.sans(weight: FontWeight.w600, color: const Color(0xFFA23B25))),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _signingOut = true);
    try {
      await _backend.signOut();
      if (mounted) context.root('login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      backgroundColor: W.screenBg,
      body: Stack(children: [
        SafeArea(
          bottom: false,
          child: StreamBuilder<UserProfile?>(
            stream: _profile,
            builder: (context, snap) {
              final p = snap.data;
              return ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  AccountHeader(title: s.t('ACCOUNT · الحساب', 'الحساب · ACCOUNT'), onBack: () => context.tab('home')),
                  _ProfileHero(profile: p, onEdit: () => _editName(p)),
                  _StatsStrip(profile: p),
                  if (_backend.isDemo) const _DemoBanner(),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(18, 20, 18, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SectionLabel(s.t('ACCOUNT', 'الحساب')),
                      ListCard(children: [
                        _SRow(
                          icon: 'user',
                          title: s.t('Profile & name', 'الملف الشخصي'),
                          detail: p == null ? null : [if (p.name.isNotEmpty) p.name, maskPhone(p.phone)].join(' · '),
                          onTap: () => _editName(p),
                        ),
                        _SRow(
                          icon: 'wallet',
                          title: s.t('Wallet', 'المحفظة'),
                          detail: p == null ? null : '${sdg(p.balance)} ${s.t('SDG', 'ج.س')}',
                          onTap: () => context.tab('wallet'),
                        ),
                        StreamBuilder<List<Place>>(
                          stream: _places,
                          builder: (context, ps) => _SRow(
                            icon: 'pin',
                            title: s.t('Saved places', 'الأماكن المحفوظة'),
                            detail: ps.data == null ? null : s.t('${ps.data!.length} shortcuts', '${ps.data!.length} اختصارات'),
                            onTap: () => context.go('saved'),
                          ),
                        ),
                        StreamBuilder<List<AppNotification>>(
                          stream: _notes,
                          builder: (context, ns) {
                            final unread = ns.data?.where((n) => !n.read).length;
                            return _SRow(
                              icon: 'bell',
                              title: s.t('Notifications', 'الإشعارات'),
                              detail: unread == null ? null : s.t('$unread unread', '$unread غير مقروءة'),
                              onTap: () => context.go('notifications'),
                            );
                          },
                        ),
                        _SRow(
                          icon: 'shield',
                          title: s.t('Safety & SOS', 'الأمان والطوارئ'),
                          detail: s.t('Emergency tools · 24/7', 'أدوات الطوارئ · ٢٤/٧'),
                          onTap: () => context.go('sos'),
                          last: true,
                        ),
                      ]),
                      const SizedBox(height: 18),
                      SectionLabel(s.t('APPEARANCE', 'المظهر')),
                      const AppearanceCard(),
                      const SizedBox(height: 18),
                      SectionLabel(s.t('ROLE', 'الدور')),
                      ListCard(children: [
                        _SRow(
                          icon: 'car',
                          title: s.t('Switch role', 'تغيير الدور'),
                          detail: switch (p?.role) {
                            UserRole.driver => s.t('Currently: Driver', 'حاليًا: سائق'),
                            UserRole.store => s.t('Currently: Store', 'حاليًا: متجر'),
                            _ => s.t('Currently: Passenger', 'حاليًا: راكب'),
                          },
                          onTap: () => context.go('role'),
                          last: true,
                        ),
                      ]),
                      const SizedBox(height: 18),
                      ListCard(children: [
                        _SRow(
                          icon: 'logout',
                          title: s.t('Sign out', 'تسجيل الخروج'),
                          danger: true,
                          loading: _signingOut,
                          onTap: _signingOut ? null : _signOut,
                          last: true,
                        ),
                      ]),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'WASILHA · v 1.0.0\n${s.t('MADE IN KHARTOUM', 'صُنع في الخرطوم')} · 🇸🇩',
                          textAlign: TextAlign.center,
                          style: W.mono(size: 10, color: W.text3, letterSpacing: 0.24).copyWith(height: 1.7),
                        ),
                      ),
                    ]),
                  ),
                ],
              );
            },
          ),
        ),
        const BottomNav(active: 'settings'),
      ]),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.onEdit});
  final UserProfile? profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = profile;
    final name = (p?.name.isNotEmpty ?? false) ? p!.name : s.t('Add your name', 'أضف اسمك');
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 24, 18, 0),
      child: Row(children: [
        GestureDetector(onTap: onEdit, child: Avatar(size: 72, label: p?.initials ?? 'W')),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: onEdit,
              child: Row(children: [
                Flexible(
                  child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: W.serif(size: 28, color: p?.name.isNotEmpty ?? false ? W.text : W.text3)),
                ),
                const SizedBox(width: 6),
                const Padding(padding: EdgeInsets.only(top: 4), child: WIcon('settings', size: 14, color: W.text3)),
              ]),
            ),
            const SizedBox(height: 6),
            if (p != null)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(maskPhone(p.phone), style: W.mono(size: 11, color: W.text2, letterSpacing: 0.08)),
              ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: s.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                WIcon('flame', size: 11, strokeWidth: 2, color: s.accent),
                const SizedBox(width: 5),
                Text(
                  (p?.trips ?? 0) >= 50
                      ? s.t('Loyal · ${p!.trips} trips', 'وفيّ · ${p.trips} رحلة')
                      : s.t('${p?.trips ?? 0} trips', '${p?.trips ?? 0} رحلة'),
                  style: W.sans(size: 11, color: s.accent),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.profile});
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = profile;
    Widget stat(String label, Widget value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: W.mono(size: 9, color: const Color(0x80FFFFFF), letterSpacing: 0.24)),
          const SizedBox(height: 6),
          value,
        ]);
    final big = W.serif(size: 36, color: Colors.white);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 20, 18, 0),
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: W.text, borderRadius: BorderRadius.circular(18)),
        child: Stack(clipBehavior: Clip.none, children: [
          PositionedDirectional(top: -46, end: -36, child: AccentGlow(color: s.accent, size: 150, opacity: 0.38, stop: 0.7)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            stat(
              s.t('YOUR RATING', 'تقييمك'),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text((p?.rating ?? 5).toStringAsFixed(2), style: big),
                const SizedBox(width: 6),
                const WIcon('star', size: 14, color: W.gold),
              ]),
            ),
            stat(s.t('TRIPS', 'الرحلات'), Text('${p?.trips ?? 0}', style: big)),
            stat(
              s.t('WALLET', 'المحفظة'),
              Text.rich(TextSpan(children: [
                TextSpan(text: p == null ? '—' : _compact(p.balance), style: big),
                TextSpan(text: s.t('SDG', 'ج.س'), style: W.mono(size: 11, color: const Color(0x99FFFFFF), letterSpacing: 0)),
              ])),
            ),
          ]),
        ]),
      ),
    );
  }

  static String _compact(int v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 10000) return '${(v / 1000).round()}K';
    return sdg(v);
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: W.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: W.gold.withValues(alpha: 0.45), width: 0.5),
        ),
        child: Row(children: [
          const WIcon('sparkle', size: 16, color: Color(0xFF8A6A10)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.t('Demo mode — data is simulated on this device. Connect Firebase to go live.',
                  'الوضع التجريبي — البيانات محاكاة على هذا الجهاز. اربط Firebase للتشغيل الفعلي.'),
              style: W.sans(size: 12, color: const Color(0xFF6B5310), height: 1.4),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SRow extends StatelessWidget {
  const _SRow({
    required this.icon,
    required this.title,
    this.detail,
    this.onTap,
    this.danger = false,
    this.last = false,
    this.loading = false,
  });
  final String icon;
  final String title;
  final String? detail;
  final VoidCallback? onTap;
  final bool danger;
  final bool last;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFA23B25);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: W.border, width: 0.5))),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: danger ? const Color(0xFFF3D7D2) : W.surface2,
              borderRadius: BorderRadius.circular(11),
            ),
            child: WIcon(icon, size: 16, strokeWidth: 1.7, color: danger ? red : W.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: W.sans(size: 14, weight: FontWeight.w500, color: danger ? red : W.text)),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(detail!, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 11.5, color: W.text2)),
              ],
            ]),
          ),
          if (loading)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: red))
          else if (!danger)
            const WIcon('chevron', size: 14, color: W.text3),
        ]),
      ),
    );
  }
}
