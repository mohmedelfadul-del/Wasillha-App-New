import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';
import 'account_common.dart';

class _Method {
  const _Method(this.id, this.icon, this.name, this.nameAr, this.detail, this.detailAr);
  final String id;
  final String icon;
  final String name;
  final String nameAr;
  final String detail;
  final String detailAr;
}

/// Formats digits with thousands separators while typing.
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final capped = digits.length > 7 ? digits.substring(0, 7) : digits;
    final txt = sdg(int.parse(capped));
    return TextEditingValue(text: txt, selection: TextSelection.collapsed(offset: txt.length));
  }
}

class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  static const _presets = [10000, 25000, 50000, 100000];
  static const _min = 5000.0;
  static const _max = 200000.0;

  late final WasilhaBackend _backend = context.read<WasilhaBackend>();
  late final Stream<UserProfile?> _profile = _backend.profile();
  final _ctrl = TextEditingController(text: sdg(25000));
  final _focus = FocusNode();

  int _amount = 25000;
  String _method = 'bankak';
  bool _loading = false;
  int? _added;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setAmount(int v) {
    setState(() => _amount = v);
    _ctrl.text = sdg(v);
  }

  List<_Method> _methods(UserProfile? p) {
    final phone = p?.phone ?? '';
    final masked = phone.length > 6 ? '${phone.substring(0, phone.length - 7)} *** ${phone.substring(phone.length - 4)}' : '+249 91 *** 5678';
    return [
      const _Method('bankak', 'wallet', 'Bankak · Bank of Khartoum', 'بنكك · بنك الخرطوم', '•• 4471', '•• ٤٤٧١'),
      _Method('mbok', 'phone', 'mBOK / Fawry', 'إم بوك / فوري', masked, masked),
      const _Method('card', 'receipt', 'Debit card', 'بطاقة مصرفية', 'Visa · Mastercard · EBS', 'فيزا · ماستركارد · EBS'),
      const _Method('cash', 'plus', 'Cash at agent', 'نقدًا في الوكيل', 'Nearest agent · 1.2 km', 'أقرب وكيل · ١٫٢ كم'),
    ];
  }

  Future<void> _submit(List<_Method> methods) async {
    final s = context.read<AppState>();
    if (_amount < 1000) {
      snack(context, s.t('Minimum top-up is 1,000 SDG', 'أقل مبلغ للشحن ١٬٠٠٠ ج.س'));
      return;
    }
    _focus.unfocus();
    final m = methods.firstWhere((m) => m.id == _method);
    setState(() => _loading = true);
    try {
      await _backend.topUp(_amount, m.name.split(' · ').first);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _added = _amount;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      backgroundColor: W.screenBg,
      body: SafeArea(
        child: StreamBuilder<UserProfile?>(
          stream: _profile,
          builder: (context, snap) {
            final p = snap.data;
            final methods = _methods(p);
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _added != null
                  ? _Success(key: const ValueKey('ok'), amount: _added!, balance: p?.balance)
                  : ListView(
                      key: const ValueKey('form'),
                      padding: const EdgeInsets.only(bottom: 40),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        AccountHeader(title: s.t('TOP-UP · شحن', 'شحن · TOP-UP')),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(18, 24, 18, 0),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            MonoLabel(s.t('● ADD FUNDS', '● شحن الرصيد'), color: s.accent, spacing: 0.32),
                            const SizedBox(height: 10),
                            SerifHeadline(s.t('How much to ', 'كم تريد أن '), s.t('add?', 'تضيف؟')),
                          ]),
                        ),
                        _amountDisplay(s, p),
                        _presetRow(s),
                        _slider(s),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(18, 24, 18, 0),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: SectionLabel(s.t('PAYMENT METHOD', 'طريقة الدفع')),
                            ),
                            for (final m in methods) ...[
                              _MethodTile(m: m, active: _method == m.id, onTap: () => setState(() => _method = m.id)),
                              const SizedBox(height: 8),
                            ],
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 18, 0),
                          child: Column(children: [
                            Btn(
                              s.t('Add ${sdg(_amount)} SDG', 'إضافة ${sdg(_amount)} ج.س'),
                              full: true,
                              icon: 'arrow',
                              loading: _loading,
                              onTap: () => _submit(methods),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              s.t('No fees · Instant processing · 256-bit encrypted', 'بدون رسوم · معالجة فورية · 256-bit مشفّر'),
                              textAlign: TextAlign.center,
                              style: W.sans(size: 10.5, color: W.text3, height: 1.5),
                            ),
                            if (_method == 'cash') ...[
                              const SizedBox(height: 6),
                              Text(
                                s.t('Show the reference in your notifications to the agent.', 'أظهر رقم المرجع في الإشعارات للوكيل.'),
                                textAlign: TextAlign.center,
                                style: W.sans(size: 10.5, color: W.text3, height: 1.5),
                              ),
                            ],
                          ]),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _amountDisplay(AppState s, UserProfile? p) {
    final newBal = (p?.balance ?? 0) + _amount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 0),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: IntrinsicWidth(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [_ThousandsFormatter()],
                  cursorColor: s.accent,
                  style: W.serif(size: 72, height: 1.05, letterSpacing: -0.035 * 72),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0',
                  ),
                  onChanged: (v) {
                    final n = int.tryParse(v.replaceAll(',', '')) ?? 0;
                    setState(() => _amount = n);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(s.t('SDG', 'ج.س'), style: W.mono(size: 14, color: W.text2, letterSpacing: 0.14)),
          ],
        ),
        const SizedBox(height: 6),
        if (p != null)
          MonoLabel(s.t('NEW BALANCE · ${sdg(newBal)} SDG', 'الرصيد الجديد · ${sdg(newBal)} ج.س'), spacing: 0.24),
      ]),
    );
  }

  Widget _presetRow(AppState s) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 24, 18, 0),
      child: Row(children: [
        for (var i = 0; i < _presets.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => _setAmount(_presets[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _amount == _presets[i] ? s.accent.withValues(alpha: 0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _amount == _presets[i] ? s.accent : W.border,
                    width: _amount == _presets[i] ? 1.5 : 0.5,
                  ),
                ),
                child: Text('+${_presets[i] ~/ 1000}K',
                    style: W.mono(size: 12.5, weight: FontWeight.w500, color: _amount == _presets[i] ? s.accent : W.text, letterSpacing: 0)),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _slider(AppState s) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 14, 6, 0),
      child: Column(children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: s.accent,
            inactiveTrackColor: W.surface3,
            thumbColor: s.accent,
            overlayColor: s.accent.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            min: _min,
            max: _max,
            divisions: ((_max - _min) / 1000).round(),
            value: _amount.toDouble().clamp(_min, _max),
            onChanged: (v) => _setAmount(v.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Text('5,000', style: W.mono(size: 9.5, letterSpacing: 0)),
            const Spacer(),
            Text(s.t('200,000 SDG', '200,000 ج.س'), style: W.mono(size: 9.5, letterSpacing: 0)),
          ]),
        ),
      ]),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.m, required this.active, required this.onTap});
  final _Method m;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? s.accent : W.border, width: active ? 1.5 : 0.5),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? s.accent.withValues(alpha: 0.07) : W.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: WIcon(m.icon, size: 18, strokeWidth: 1.7, color: active ? s.accent : W.text),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.t(m.name, m.nameAr), style: W.sans(size: 14, weight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(s.t(m.detail, m.detailAr), textDirection: m.id == 'mbok' ? TextDirection.ltr : null, style: W.sans(size: 11.5, color: W.text2)),
            ]),
          ),
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: active ? s.accent : W.border2, width: 1.5),
            ),
            child: active
                ? Container(width: 9, height: 9, decoration: BoxDecoration(color: s.accent, shape: BoxShape.circle))
                : null,
          ),
        ]),
      ),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({super.key, required this.amount, required this.balance});
  final int amount;
  final int? balance;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: W.success,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: W.success.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 12))],
                ),
                child: const WIcon('check', size: 38, strokeWidth: 2.2, color: Colors.white),
              ),
              const SizedBox(height: 24),
              MonoLabel(s.t('● TOP-UP COMPLETE', '● تم الشحن'), color: W.success, spacing: 0.3),
              const SizedBox(height: 10),
              SerifHeadline(s.t('Funds ', 'تمت '), s.t('added.', 'الإضافة.'), size: 40),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('+${sdg(amount)}', style: W.serif(size: 56)),
                  const SizedBox(width: 6),
                  Text(s.t('SDG', 'ج.س'), style: W.mono(size: 13, color: W.text2)),
                ],
              ),
              if (balance != null) ...[
                const SizedBox(height: 8),
                MonoLabel(s.t('BALANCE · ${sdg(balance!)} SDG', 'الرصيد · ${sdg(balance!)} ج.س'), spacing: 0.24),
              ],
              const SizedBox(height: 36),
              Btn(s.t('Back to wallet', 'العودة للمحفظة'), full: true, variant: BtnVariant.dark, onTap: () => context.back()),
            ]),
          ),
        ),
      ),
    );
  }
}
