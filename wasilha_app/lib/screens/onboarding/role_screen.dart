import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../data/backend.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';
import 'auth_common.dart';

/// 17 — Role selection + profile basics.
class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  UserRole _role = UserRole.rider;
  final _name = TextEditingController();
  final _vehicle = TextEditingController();
  final _plate = TextEditingController();
  String? _storeId;
  bool _saving = false;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    try {
      final p = await firstProfile(context.read<WasilhaBackend>());
      if (!mounted || p == null) return;
      setState(() {
        if (_name.text.isEmpty) _name.text = p.name;
        if (_vehicle.text.isEmpty) _vehicle.text = p.vehicle;
        if (_plate.text.isEmpty) _plate.text = p.plate;
        if (Catalog.restaurants.any((r) => r.id == p.storeName)) _storeId = p.storeName;
        if (p.name.trim().isNotEmpty) _role = p.role;
      });
    } catch (_) {
      // No profile yet — keep defaults.
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _vehicle.dispose();
    _plate.dispose();
    super.dispose();
  }

  String? _problem(AppState s) {
    if (_name.text.trim().isEmpty) return s.t('Please enter your name.', 'من فضلك أدخل اسمك.');
    if (_role == UserRole.driver && (_vehicle.text.trim().isEmpty || _plate.text.trim().isEmpty)) {
      return s.t('Add your vehicle and plate number.', 'أضف مركبتك ورقم اللوحة.');
    }
    if (_role == UserRole.store && _storeId == null) return s.t('Choose your store.', 'اختر متجرك.');
    return null;
  }

  Future<void> _continue() async {
    final s = context.read<AppState>();
    setState(() => _tried = true);
    final p = _problem(s);
    if (p != null) {
      showError(context, p);
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<WasilhaBackend>().updateProfile(
            name: _name.text.trim(),
            role: _role,
            vehicle: _role == UserRole.driver ? _vehicle.text.trim() : null,
            plate: _role == UserRole.driver ? _plate.text.trim().toUpperCase() : null,
            storeName: _role == UserRole.store ? _storeId : null,
          );
      if (!mounted) return;
      context.root(routeForRole(_role));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final roles = [
      (UserRole.rider, 'user', s.t('Passenger', 'راكب'), s.t('Book Raksha, car, motorcycle & courier', 'احجز الراكشة والسيارة والدراجة والتوصيل'),
          s.t('MOST COMMON', 'الأكثر شيوعًا')),
      (UserRole.driver, 'car', s.t('Driver', 'سائق'), s.t('Accept ride requests, track daily earnings', 'اقبل طلبات الرحلات وتتبع أرباحك اليومية'),
          s.t('120K SDG / WEEK AVG', '+ ١٢٠ ألف ج.س / أسبوع')),
      (UserRole.store, 'bag', s.t('Store', 'متجر'), s.t('Manage orders, dispatch couriers from branches', 'أدر طلباتك واطلب توصيل من فروعك'),
          s.t('420+ PARTNERS', 'شركاء ٤٢٠+')),
    ];

    return Scaffold(
      backgroundColor: W.screenBg,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (Navigator.of(context).canPop())
                    AuthBackBtn(onTap: () => context.back(), child: const WIcon('back', size: 18, strokeWidth: 1.7))
                  else
                    const SizedBox(width: 40, height: 40),
                  Expanded(
                    child: Center(
                      child: Text(s.t('STEP 03 / ROLE', 'الخطوة ٠٣ / الدور'),
                          style: s.ar ? W.ar(size: 12, color: W.text3) : W.mono(size: 10, color: W.text3, letterSpacing: 0.3)),
                    ),
                  ),
                  const SizedBox(width: 40),
                ]),
                const SizedBox(height: 32),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: s.t('How will you use ', 'كيف ستستخدم ')),
                    TextSpan(text: s.t('Wasilha?', 'وصلها؟'), style: TextStyle(color: accent)),
                  ]),
                  style: s.ar ? W.arSerif(size: 36, height: 1.2) : W.serif(size: 40, letterSpacing: -1),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    s.t('You can switch between roles anytime from account settings.',
                        'يمكنك التبديل بين الأدوار في أي وقت من إعدادات الحساب.'),
                    style: s.ar ? W.ar(size: 13.5, color: W.text2, height: 1.55) : W.sans(size: 13.5, color: W.text2, height: 1.55),
                  ),
                ),
                const SizedBox(height: 28),
                for (final (role, icon, name, sub, tag) in roles) ...[
                  _RoleCard(
                    on: _role == role,
                    icon: icon,
                    name: name,
                    sub: sub,
                    tag: tag,
                    onTap: () => setState(() => _role = role),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 18),
                MonoLabel(s.t('YOUR DETAILS', 'بياناتك')),
                const SizedBox(height: 10),
                _Field(
                  controller: _name,
                  icon: 'user',
                  hint: s.t('Full name', 'الاسم الكامل'),
                  error: _tried && _name.text.trim().isEmpty,
                  onChanged: () => setState(() {}),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment: AlignmentDirectional.topStart,
                  child: switch (_role) {
                    UserRole.driver => Column(children: [
                        const SizedBox(height: 10),
                        _Field(
                          controller: _vehicle,
                          icon: 'car',
                          hint: s.t('Vehicle (e.g. Toyota Corolla · White)', 'المركبة (مثال: تويوتا كورولا · أبيض)'),
                          error: _tried && _vehicle.text.trim().isEmpty,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        _Field(
                          controller: _plate,
                          icon: 'receipt',
                          hint: s.t('Plate number (e.g. KRT 4421)', 'رقم اللوحة (مثال: KRT 4421)'),
                          error: _tried && _plate.text.trim().isEmpty,
                          caps: true,
                          onChanged: () => setState(() {}),
                        ),
                      ]),
                    UserRole.store => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(height: 18),
                        MonoLabel(s.t('YOUR STORE', 'متجرك'),
                            color: _tried && _storeId == null ? W.danger : null),
                        const SizedBox(height: 10),
                        for (final r in Catalog.restaurants)
                          _StoreOption(
                            restaurant: r,
                            on: _storeId == r.id,
                            onTap: () => setState(() => _storeId = r.id),
                          ),
                      ]),
                    UserRole.rider => const SizedBox(width: double.infinity),
                  },
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Btn(s.t('Continue', 'متابعة'), full: true, icon: 'arrow', loading: _saving, onTap: _continue),
          ),
        ]),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.on, required this.icon, required this.name, required this.sub, required this.tag, required this.onTap});
  final bool on;
  final String icon, name, sub, tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: on ? Colors.white : const Color(0x99FFFFFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: on ? accent : W.border, width: on ? 1.5 : 0.5),
          boxShadow: on
              ? [BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 32, offset: const Offset(0, 14))]
              : const [BoxShadow(color: Color(0x0A140F1E), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Stack(children: [
          if (on)
            PositionedDirectional(
              top: -40,
              end: -40,
              child: IgnorePointer(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [accent.withValues(alpha: 0.19), accent.withValues(alpha: 0)], stops: const [0, 0.7]),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? accent : W.surface2,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: on ? [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8))] : null,
                ),
                child: WIcon(icon, size: 26, strokeWidth: 1.5, color: on ? Colors.white : W.text),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: s.ar ? W.arSerif(size: 24, height: 1.1) : W.serif(size: 24, letterSpacing: -0.24)),
                  const SizedBox(height: 4),
                  Text(sub, style: s.ar ? W.ar(size: 12, color: W.text2, height: 1.45) : W.sans(size: 12, color: W.text2, height: 1.45)),
                  const SizedBox(height: 7),
                  Text('● $tag',
                      style: s.ar
                          ? W.ar(size: 11, color: on ? accent : W.text3)
                          : W.mono(size: 9.5, color: on ? accent : W.text3, letterSpacing: 0.22)),
                ]),
              ),
              const SizedBox(width: 8),
              _Radio(on: on, accent: accent),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.on, required this.accent});
  final bool on;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? accent : W.border2, width: 1.5)),
        child: on ? Container(width: 11, height: 11, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)) : null,
      );
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.icon, required this.hint, required this.error, required this.onChanged, this.caps = false});
  final TextEditingController controller;
  final String icon, hint;
  final bool error, caps;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final style = s.ar ? W.ar(size: 15) : W.sans(size: 15);
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 14, end: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: error ? W.danger : W.border, width: error ? 1 : 0.5),
        boxShadow: const [BoxShadow(color: Color(0x0D140F1E), blurRadius: 22, offset: Offset(0, 8))],
      ),
      child: Row(children: [
        WIcon(icon, size: 18, color: W.text2),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.words,
            cursorColor: s.accent,
            style: style,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: style.copyWith(color: W.text3),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ]),
    );
  }
}

class _StoreOption extends StatelessWidget {
  const _StoreOption({required this.restaurant, required this.on, required this.onTap});
  final Restaurant restaurant;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final r = restaurant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: on ? accent : W.border, width: on ? 1.5 : 0.5),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: on ? accent.withValues(alpha: 0.1) : W.surface2, borderRadius: BorderRadius.circular(12)),
              child: WIcon('bowl', size: 18, color: on ? accent : W.text),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.label(s.ar), style: s.ar ? W.ar(size: 14, weight: FontWeight.w500) : W.sans(size: 14, weight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('${r.cuisine} · ${r.place.area}', style: W.sans(size: 12, color: W.text2)),
              ]),
            ),
            _Radio(on: on, accent: accent),
          ]),
        ),
      ),
    );
  }
}
