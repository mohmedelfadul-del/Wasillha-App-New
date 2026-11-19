import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/nav.dart';
import '../theme/tokens.dart';
import 'w_icon.dart';

/// Frosted surface (components.jsx → Glass). [intensity] 0–100.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.intensity,
    this.dark = false,
    this.radius = 999,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double? intensity;
  final bool dark;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final i = intensity ?? context.watch<AppState>().glass;
    final blur = 8 + i / 100 * 24;
    final tint = dark
        ? Color.fromRGBO(20, 18, 16, (0.5 + i / 400).clamp(0, 1))
        : Color.fromRGBO(255, 255, 255, (0.4 + i / 250).clamp(0, 1));
    final br = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: dark
            ? const [BoxShadow(color: Color(0x4D000000), blurRadius: 30, offset: Offset(0, 10))]
            : W.softShadow,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur / 2, sigmaY: blur / 2),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: br,
              border: Border.all(
                color: dark ? const Color(0x14FFFFFF) : const Color(0xB3FFFFFF),
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

enum BtnVariant { primary, dark, secondary, ghost, light }

/// Pill button (components.jsx → Btn).
class Btn extends StatefulWidget {
  const Btn(
    this.label, {
    super.key,
    this.onTap,
    this.variant = BtnVariant.primary,
    this.icon,
    this.full = false,
    this.onDark = false,
    this.loading = false,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onTap;
  final BtnVariant variant;
  final String? icon;
  final bool full;
  final bool onDark;
  final bool loading;
  final double height;

  @override
  State<Btn> createState() => _BtnState();
}

class _BtnState extends State<Btn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<AppState>().accent;
    final v = widget.variant;
    final bg = switch (v) {
      BtnVariant.primary => accent,
      BtnVariant.dark => W.text,
      BtnVariant.secondary => widget.onDark ? const Color(0x14FFFFFF) : W.surface2,
      BtnVariant.ghost => Colors.transparent,
      BtnVariant.light => Colors.white,
    };
    final fg = switch (v) {
      BtnVariant.primary || BtnVariant.dark => Colors.white,
      BtnVariant.secondary || BtnVariant.ghost => widget.onDark ? Colors.white : W.text,
      BtnVariant.light => W.text,
    };
    final disabled = widget.onTap == null || widget.loading;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: disabled ? null : widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: widget.onTap == null ? 0.45 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: widget.height,
            width: widget.full ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: v == BtnVariant.ghost
                  ? Border.all(color: widget.onDark ? const Color(0x33FFFFFF) : W.border2, width: 0.5)
                  : null,
              boxShadow: switch (v) {
                BtnVariant.primary => [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 22, offset: const Offset(0, 8))],
                BtnVariant.dark => const [BoxShadow(color: Color(0x400A0908), blurRadius: 22, offset: Offset(0, 8))],
                _ => null,
              },
            ),
            child: Row(
              mainAxisSize: widget.full ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading)
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
                else ...[
                  Flexible(
                    child: Text(widget.label,
                        overflow: TextOverflow.ellipsis,
                        style: W.sans(size: 15, weight: FontWeight.w500, color: fg)),
                  ),
                  if (widget.icon != null) ...[
                    const SizedBox(width: 8),
                    WIcon(widget.icon!, size: 18, strokeWidth: 1.8, color: fg),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient initials avatar.
class Avatar extends StatelessWidget {
  const Avatar({super.key, this.size = 40, this.label = 'AH', this.tone = 'warm'});
  final double size;
  final String label;

  /// warm | cool | purple | olive
  final String tone;

  static const _tones = {
    'warm': [Color(0xFFE8D9C4), Color(0xFFC9B59A)],
    'cool': [Color(0xFFD4DDE5), Color(0xFFA8B5C2)],
    'purple': [Color(0xFFE0CCEF), Color(0xFFB894D3)],
    'olive': [Color(0xFFD6D6BC), Color(0xFFA8A88A)],
  };

  @override
  Widget build(BuildContext context) {
    final c = _tones[tone] ?? _tones['warm']!;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: c, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Text(label,
          style: W.sans(size: size * 0.32, weight: FontWeight.w600, color: Colors.white, letterSpacing: size * 0.32 * 0.04)),
    );
  }
}

/// List row with icon tile (components.jsx → Row).
class WRow extends StatelessWidget {
  const WRow({
    super.key,
    this.icon,
    required this.title,
    this.detail,
    this.trailing,
    this.onTap,
    this.dark = false,
    this.divider = true,
  });

  final String? icon;
  final String title;
  final String? detail;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dark;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : W.text;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: divider
              ? Border(bottom: BorderSide(color: dark ? const Color(0x0FFFFFFF) : W.border, width: 0.5))
              : null,
        ),
        child: Row(children: [
          if (icon != null) ...[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dark ? const Color(0x0FFFFFFF) : W.surface2,
                borderRadius: BorderRadius.circular(11),
              ),
              child: WIcon(icon!, size: 18, color: fg),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: W.sans(size: 14.5, weight: FontWeight.w500, color: fg)),
              if (detail != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(detail!,
                      style: W.sans(size: 12, color: dark ? const Color(0x8CFFFFFF) : W.text2)),
                ),
            ]),
          ),
          ?trailing,
        ]),
      ),
    );
  }
}

/// Uppercase mono micro-label ("SERVICES", "CURRENT LOCATION").
class MonoLabel extends StatelessWidget {
  const MonoLabel(this.text, {super.key, this.color, this.size = 10, this.spacing = 0.22});
  final String text;
  final Color? color;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final ar = context.watch<AppState>().ar;
    // Arabic has no case and letter-spacing breaks joined glyphs.
    if (ar && RegExp(r'[؀-ۿ]').hasMatch(text)) {
      return Text(text, style: W.ar(size: size + 1.5, color: color ?? W.text3));
    }
    return Text(text.toUpperCase(), style: W.mono(size: size, color: color ?? W.text3, letterSpacing: spacing));
  }
}

/// Round 40px icon button used in screen headers.
class CircleBtn extends StatelessWidget {
  const CircleBtn({super.key, required this.icon, this.onTap, this.dark = false, this.glass = false, this.size = 40, this.badge = false});
  final String icon;
  final VoidCallback? onTap;
  final bool dark;
  final bool glass;
  final double size;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<AppState>().accent;
    final inner = SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        WIcon(icon, size: 18, strokeWidth: 1.7, color: dark ? Colors.white : W.text),
        if (badge)
          Positioned(
            top: size * 0.22,
            right: size * 0.24,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
            ),
          ),
      ]),
    );
    return GestureDetector(
      onTap: onTap,
      child: glass
          ? Glass(dark: dark, child: inner)
          : Container(
              decoration: BoxDecoration(
                color: dark ? const Color(0x14FFFFFF) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: dark ? const Color(0x1AFFFFFF) : const Color(0x0F000000), width: 0.5),
                boxShadow: dark ? null : W.cardShadow,
              ),
              child: inner,
            ),
    );
  }
}

/// Standard screen header: back button · centered mono title · trailing.
class TopBar extends StatelessWidget {
  const TopBar({super.key, this.title, this.trailing, this.dark = false, this.onBack, this.leadingIcon = 'back'});
  final String? title;
  final Widget? trailing;
  final bool dark;
  final VoidCallback? onBack;
  final String leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(children: [
        CircleBtn(icon: leadingIcon, dark: dark, onTap: onBack ?? () => context.back()),
        Expanded(
          child: Center(
            child: title == null
                ? const SizedBox()
                : MonoLabel(title!, color: dark ? const Color(0x99FFFFFF) : W.text2, spacing: 0.24),
          ),
        ),
        trailing ?? const SizedBox(width: 40),
      ]),
    );
  }
}

/// Rider bottom nav (Home / Wallet / History / Account).
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.active});
  final String active;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final items = [
      ('home', s.t('Home', 'الرئيسية'), 'home'),
      ('wallet', s.t('Wallet', 'المحفظة'), 'wallet'),
      ('history', s.t('History', 'الرحلات'), 'history'),
      ('settings', s.t('Account', 'حسابي'), 'user'),
    ];
    return Positioned(
      left: 12,
      right: 12,
      bottom: 22 + MediaQuery.paddingOf(context).bottom * 0.4,
      child: Center(
        child: Glass(
          padding: const EdgeInsets.all(8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final (id, label, icon) in items)
              GestureDetector(
                onTap: () => id == active ? null : context.tab(id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 44,
                  constraints: const BoxConstraints(minWidth: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: active == id ? W.text : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    WIcon(icon, size: 18, strokeWidth: 1.7, color: active == id ? Colors.white : W.text),
                    if (active == id) ...[
                      const SizedBox(width: 8),
                      Text(label, style: W.sans(size: 13, weight: FontWeight.w500, color: Colors.white)),
                    ],
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Light card container used across list screens.
class WCard extends StatelessWidget {
  const WCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 18, this.color = Colors.white, this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0x0F000000), width: 0.5),
        boxShadow: W.cardShadow,
      ),
      child: child,
    );
    return onTap == null ? c : GestureDetector(onTap: onTap, child: c);
  }
}

/// Snack helper for backend errors.
void showError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(e.toString()),
    behavior: SnackBarBehavior.floating,
    backgroundColor: W.text,
  ));
}

/// "2 min ago" style relative time.
String timeAgo(DateTime t, {bool ar = false}) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return ar ? 'الآن' : 'just now';
  if (d.inMinutes < 60) return ar ? 'منذ ${d.inMinutes} د' : '${d.inMinutes} min ago';
  if (d.inHours < 24) return ar ? 'منذ ${d.inHours} س' : '${d.inHours} h ago';
  if (d.inDays == 1) return ar ? 'أمس' : 'yesterday';
  return ar ? 'منذ ${d.inDays} يوم' : '${d.inDays} days ago';
}
