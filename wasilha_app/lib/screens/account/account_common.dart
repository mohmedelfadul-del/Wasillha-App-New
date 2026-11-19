import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';

/// Rounded-square 40px header button used by the account screens.
class SquareBtn extends StatelessWidget {
  const SquareBtn({super.key, required this.icon, this.onTap, this.dark = false, this.color, this.fg});
  final String icon;
  final VoidCallback? onTap;
  final bool dark;
  final Color? color;
  final Color? fg;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? (dark ? const Color(0x14FFFFFF) : Colors.white);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: dark || color != null
              ? null
              : const [BoxShadow(color: Color(0x0F140F1E), blurRadius: 14, offset: Offset(0, 4))],
        ),
        child: WIcon(icon, size: 18, strokeWidth: 1.7, color: fg ?? (dark ? Colors.white : W.text)),
      ),
    );
  }
}

/// Header row: back · mono title · trailing.
class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key, required this.title, this.trailing, this.onBack, this.dark = false, this.leadingIcon = 'back'});
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool dark;
  final String leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 18, 0),
      child: Row(children: [
        SquareBtn(icon: leadingIcon, dark: dark, onTap: onBack ?? () => context.back()),
        Expanded(
          child: Center(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: W.mono(size: 10, color: dark ? const Color(0x8CFFFFFF) : W.text3, letterSpacing: 0.3)),
          ),
        ),
        trailing ?? const SizedBox(width: 40),
      ]),
    );
  }
}

/// Serif headline with an accent-coloured last part: "Where you've **been.**"
class SerifHeadline extends StatelessWidget {
  const SerifHeadline(this.lead, this.accentPart, {super.key, this.size = 40, this.color = W.text, this.accentColor});
  final String lead;
  final String accentPart;
  final double size;
  final Color color;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final base = s.ar ? W.arSerif(size: size * 0.9, color: color, height: 1.15) : W.serif(size: size, color: color);
    return Text.rich(TextSpan(style: base, children: [
      TextSpan(text: lead),
      TextSpan(text: accentPart, style: TextStyle(color: accentColor ?? s.accent)),
    ]));
  }
}

/// Section micro-label (mono, wide spacing).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: MonoLabel(text, size: 9.5, spacing: 0.3, color: color),
      );
}

/// Soft radial glow placed in a corner of dark cards.
class AccentGlow extends StatelessWidget {
  const AccentGlow({super.key, required this.color, this.size = 200, this.opacity = 0.5, this.stop = 0.6});
  final Color color;
  final double size;
  final double opacity;
  final double stop;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
              stops: [0, stop],
            ),
          ),
        ),
      );
}

/// White bordered list container with 16px horizontal padding.
class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: W.border, width: 0.5),
        ),
        child: Column(children: children),
      );
}

class Loading extends StatelessWidget {
  const Loading({super.key, this.color});
  final Color? color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: color ?? W.text3)),
        ),
      );
}

class EmptyNote extends StatelessWidget {
  const EmptyNote({super.key, required this.icon, required this.text});
  final String icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(children: [
          WIcon(icon, size: 26, color: W.text3),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: W.sans(size: 13, color: W.text2)),
        ]),
      );
}

// ── Date helpers ─────────────────────────────────────────────

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// "Today · 18:22", "Yesterday", "Mon · 21:10", "12 May".
String whenLabel(DateTime t, bool ar) {
  final now = DateTime.now();
  final loc = ar ? 'ar' : 'en';
  final hm = DateFormat('HH:mm', loc).format(t);
  if (sameDay(t, now)) return ar ? 'اليوم · $hm' : 'Today · $hm';
  if (sameDay(t, now.subtract(const Duration(days: 1)))) return ar ? 'أمس · $hm' : 'Yesterday · $hm';
  if (now.difference(t).inDays < 7) return '${DateFormat('EEE', loc).format(t)} · $hm';
  return DateFormat('d MMM', loc).format(t);
}

/// Group header: "TODAY · 21 MAY", "YESTERDAY · 20 MAY", "18 MAY".
String dayLabel(DateTime t, bool ar) {
  final now = DateTime.now();
  final loc = ar ? 'ar' : 'en';
  final dm = DateFormat('d MMM', loc).format(t);
  if (sameDay(t, now)) return ar ? 'اليوم · $dm' : 'Today · $dm';
  if (sameDay(t, now.subtract(const Duration(days: 1)))) return ar ? 'أمس · $dm' : 'Yesterday · $dm';
  return DateFormat(t.year == now.year ? 'EEE · d MMM' : 'd MMM yyyy', loc).format(t);
}

void snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, backgroundColor: W.text));
}
