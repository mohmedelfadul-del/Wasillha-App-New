import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';

/// Line icons from components.jsx (24px viewBox, stroke = current color).
/// `fill="C"` marks shapes that are filled with the icon color.
const Map<String, String> _paths = {
  'search': '<circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/>',
  'bell': '<path d="M18 16v-5a6 6 0 0 0-12 0v5l-2 2v1h16v-1l-2-2Z"/><path d="M10 21a2 2 0 0 0 4 0"/>',
  'pin': '<path d="M12 22s7-6.5 7-12a7 7 0 1 0-14 0c0 5.5 7 12 7 12Z"/><circle cx="12" cy="10" r="2.5"/>',
  'pindot': '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="3" fill="C"/>',
  'car': '<path d="M4 14V11l2-5h12l2 5v3"/><path d="M3 14h18v4H3z"/><circle cx="7.5" cy="18" r="1.5"/><circle cx="16.5" cy="18" r="1.5"/>',
  'raksha': '<path d="M3 16V12l3-5h9l3 5v4"/><path d="M3 16h18"/><circle cx="6" cy="18" r="1.6"/><circle cx="12" cy="18" r="1.6"/><circle cx="18" cy="18" r="1.6"/><path d="M10 7v5"/>',
  'bike': '<circle cx="6" cy="17" r="3"/><circle cx="18" cy="17" r="3"/><path d="M6 17l4-8h4l3 8"/><path d="M10 9l-1-3h-2"/>',
  'bag': '<path d="M5 8h14l-1 12H6z"/><path d="M9 8V6a3 3 0 0 1 6 0v2"/>',
  'bowl': '<path d="M3 11h18a9 9 0 0 1-18 0Z"/><path d="M3 11c0-2 4-4 9-4s9 2 9 4"/><path d="M12 4v3"/>',
  'clock': '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  'arrow': '<path d="M5 12h14"/><path d="m13 5 7 7-7 7"/>',
  'chevron': '<path d="m9 6 6 6-6 6"/>',
  'chevDown': '<path d="m6 9 6 6 6-6"/>',
  'back': '<path d="M19 12H5"/><path d="m12 19-7-7 7-7"/>',
  'close': '<path d="m6 6 12 12"/><path d="m18 6-12 12"/>',
  'plus': '<path d="M12 5v14"/><path d="M5 12h14"/>',
  'minus': '<path d="M5 12h14"/>',
  'home': '<path d="M3 11 12 3l9 8"/><path d="M5 10v10h14V10"/>',
  'wallet': '<path d="M3 7v12a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-9H5a2 2 0 0 1 0-4h12V5"/><circle cx="17" cy="14" r="1.2" fill="C"/>',
  'history': '<path d="M3 12a9 9 0 1 0 3-6.7"/><path d="M3 4v5h5"/><path d="M12 8v5l3 2"/>',
  'user': '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
  'star': '<path d="m12 3 2.7 5.7L21 9.6l-4.7 4.4 1.2 6.4L12 17.3 6.5 20.4l1.2-6.4L3 9.6l6.3-.9z"/>',
  'phone': '<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2Z"/>',
  'chat': '<path d="M21 12a8 8 0 0 1-12 7l-5 1 1-5a8 8 0 1 1 16-3Z"/>',
  'shield': '<path d="M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6Z"/>',
  'plane': '<path d="M22 12 4 4l2 8-2 8z"/><path d="m6 12 14 0"/>',
  'work': '<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M9 7V5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/>',
  'moon': '<path d="M21 13A9 9 0 1 1 11 3a7 7 0 0 0 10 10Z"/>',
  'sun': '<circle cx="12" cy="12" r="4"/><path d="M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M5.6 18.4 7 17M17 7l1.4-1.4"/>',
  'settings': '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 0 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 0 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 0 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 0 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z"/>',
  'check': '<path d="m5 12 5 5 9-11"/>',
  'target': '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1" fill="C"/>',
  'nav': '<path d="m3 11 18-8-8 18-2-8z"/>',
  'eye': '<path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7S1 12 1 12Z"/><circle cx="12" cy="12" r="3"/>',
  'flame': '<path d="M12 2s4 5 4 9a4 4 0 0 1-8 0c0-1 .5-2 1-3-2 1-3 3-3 5a6 6 0 0 0 12 0c0-5-6-11-6-11Z"/>',
  'gift': '<rect x="3" y="8" width="18" height="4"/><path d="M5 12v10h14V12M12 8v14"/><path d="M12 8s-2-5-5-5-2 5 5 5ZM12 8s2-5 5-5 2 5-5 5Z"/>',
  'receipt': '<path d="M5 3h14v18l-2-2-2 2-2-2-2 2-2-2-2 2-2-2z"/><path d="M8 8h8M8 12h8M8 16h5"/>',
  'earth': '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>',
  'help': '<circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 1 1 3.5 2.3c-.7.4-1 .8-1 1.7"/><circle cx="12" cy="17" r="0.6" fill="C"/>',
  'logout': '<path d="M10 17l-5-5 5-5"/><path d="M5 12h12"/><path d="M21 5v14"/>',
  'sparkle': '<path d="M12 3v6M12 15v6M3 12h6M15 12h6"/>',
};

/// Icons that point "forward" and should mirror in RTL.
const _directional = {'arrow', 'chevron', 'back'};

bool hasWIcon(String name) => _paths.containsKey(name);

class WIcon extends StatelessWidget {
  const WIcon(
    this.name, {
    super.key,
    this.size = 22,
    this.strokeWidth = 1.6,
    this.color,
    this.mirrorInRtl = true,
  });

  final String name;
  final double size;
  final double strokeWidth;
  final Color? color;
  final bool mirrorInRtl;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color ?? W.text;
    final hex = colorHex(c);
    final opacity = c.a;
    final body = (_paths[name] ?? _paths['sparkle']!).replaceAll('fill="C"', 'fill="$hex"');
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
        'stroke="$hex" stroke-opacity="$opacity" stroke-width="$strokeWidth" '
        'stroke-linecap="round" stroke-linejoin="round">$body</svg>';
    Widget w = SvgPicture.string(svg, width: size, height: size);
    if (mirrorInRtl && _directional.contains(name) && Directionality.of(context) == TextDirection.rtl) {
      w = Transform.flip(flipX: true, child: w);
    }
    return SizedBox(width: size, height: size, child: w);
  }
}
