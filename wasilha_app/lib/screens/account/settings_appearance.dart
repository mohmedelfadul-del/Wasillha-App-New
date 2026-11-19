import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';

/// The prototype's "Tweaks" panel, as a Settings section wired to [AppState].
class AppearanceCard extends StatelessWidget {
  const AppearanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: W.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Item(
          icon: 'earth',
          title: s.t('Language', 'اللغة'),
          child: _Segmented(
            value: s.lang,
            options: const [('en', 'English'), ('ar', 'العربية')],
            onChanged: s.setLang,
          ),
        ),
        _Item(
          icon: 'sparkle',
          title: s.t('Accent', 'اللون المميز'),
          child: Wrap(spacing: 10, runSpacing: 10, children: [
            for (final c in W.accentOptions)
              GestureDetector(
                onTap: () => s.setAccent(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34,
                  height: 34,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: s.accent.toARGB32() == c.toARGB32() ? c : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                    child: s.accent.toARGB32() == c.toARGB32()
                        ? const WIcon('check', size: 14, strokeWidth: 2.2, color: Colors.white)
                        : null,
                  ),
                ),
              ),
          ]),
        ),
        _Item(
          icon: 'eye',
          title: s.t('Glass intensity', 'شفافية الزجاج'),
          trailing: Text('${s.glass.round()}', style: W.mono(size: 12, color: W.text2, letterSpacing: 0)),
          child: Column(children: [
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: s.accent,
                inactiveTrackColor: W.surface3,
                thumbColor: s.accent,
                overlayColor: s.accent.withValues(alpha: 0.12),
                trackHeight: 3,
                showValueIndicator: ShowValueIndicator.never,
              ),
              child: Slider(
                min: 0,
                max: 100,
                divisions: 20,
                value: s.glass.clamp(0, 100),
                onChanged: s.setGlass,
              ),
            ),
            // Live preview of the frosted surface.
            Container(
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(colors: [s.accent, W.paper, W.text], begin: AlignmentDirectional.centerStart, end: AlignmentDirectional.centerEnd),
              ),
              alignment: Alignment.center,
              child: Glass(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: Text(s.t('Preview', 'معاينة'), style: W.sans(size: 12.5, weight: FontWeight.w500)),
              ),
            ),
          ]),
        ),
        _Item(
          icon: 'home',
          title: s.t('Home service cards', 'بطاقات الخدمات'),
          child: _Segmented(
            value: s.cardLayout,
            options: [('pairs', s.t('Pairs', 'أزواج')), ('grid', s.t('Grid', 'شبكة')), ('row', s.t('Row', 'صف'))],
            onChanged: s.setCardLayout,
          ),
        ),
        _Item(
          icon: 'pin',
          title: s.t('Map style', 'نمط الخريطة'),
          last: true,
          child: _Segmented(
            value: s.mapStyle,
            options: [
              ('white', s.t('White', 'فاتح')),
              ('dark', s.t('Dark', 'داكن')),
              ('illustrated', s.t('Illustrated', 'مرسوم')),
            ],
            onChanged: s.setMapStyle,
          ),
        ),
      ]),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.title, required this.child, this.trailing, this.last = false});
  final String icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 14),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: W.border, width: 0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: W.surface2, borderRadius: BorderRadius.circular(9)),
            child: WIcon(icon, size: 14, strokeWidth: 1.7),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: W.sans(size: 14, weight: FontWeight.w500))),
          ?trailing,
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.value, required this.options, required this.onChanged});
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: W.surface2, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        for (final (id, label) in options)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == id ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: value == id ? const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))] : null,
                ),
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: W.sans(size: 12.5, weight: value == id ? FontWeight.w600 : FontWeight.w400, color: value == id ? W.text : W.text2)),
              ),
            ),
          ),
      ]),
    );
  }
}
