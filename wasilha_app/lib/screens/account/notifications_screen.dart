import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';
import 'account_common.dart';

String _iconFor(String kind) => switch (kind) {
      'trip' => 'car',
      'promo' => 'gift',
      'wallet' => 'wallet',
      'safety' => 'shield',
      _ => 'bell',
    };

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final WasilhaBackend _backend = context.read<WasilhaBackend>();
  late final Stream<List<AppNotification>> _stream = _backend.notifications();

  /// Ids that were unread when the screen opened — they keep the unread
  /// styling for this visit even after we mark everything read.
  Set<String>? _unreadOnOpen;
  bool _marked = false;

  void _onFirstData(List<AppNotification> list) {
    if (_unreadOnOpen != null) return;
    _unreadOnOpen = {for (final n in list) if (!n.read) n.id};
    if (_unreadOnOpen!.isNotEmpty && !_marked) {
      _marked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _backend.markNotificationsRead();
        } catch (e) {
          if (mounted) showError(context, e);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      backgroundColor: W.screenBg,
      body: SafeArea(
        child: StreamBuilder<List<AppNotification>>(
          stream: _stream,
          builder: (context, snap) {
            final list = snap.data;
            if (list != null) _onFirstData(list);
            final sorted = [...?list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final unread = _unreadOnOpen ?? const <String>{};
            final now = DateTime.now();
            final today = sorted.where((n) => sameDay(n.createdAt, now)).toList();
            final earlier = sorted.where((n) => !sameDay(n.createdAt, now)).toList();
            // New notifications that arrive while the screen is open count as unread too.
            bool isUnread(AppNotification n) => unread.contains(n.id) || !n.read;
            final unreadCount = sorted.where(isUnread).length;
            return ListView(
              padding: const EdgeInsets.only(bottom: 60),
              children: [
                AccountHeader(
                  title: s.t('NOTIFICATIONS', 'الإشعارات'),
                  trailing: SizedBox(
                    width: 64,
                    child: unreadCount == 0
                        ? null
                        : GestureDetector(
                            onTap: () async {
                              setState(() => _unreadOnOpen = {});
                              try {
                                await _backend.markNotificationsRead();
                              } catch (e) {
                                if (context.mounted) showError(context, e);
                              }
                            },
                            child: Text(s.t('Mark read', 'تحديد كمقروء'),
                                textAlign: TextAlign.end, style: W.sans(size: 12, color: s.accent)),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 24, 18, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SerifHeadline(s.t("What's ", 'ما '), s.t('new.', 'الجديد.'), size: 38),
                    const SizedBox(height: 8),
                    Text(
                      s.t('$unreadCount unread · ${sorted.length} total', '$unreadCount غير مقروءة · ${sorted.length} الإجمالي'),
                      style: W.sans(size: 13, color: W.text2),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 24, 18, 0),
                  child: list == null
                      ? const Loading()
                      : sorted.isEmpty
                          ? EmptyNote(icon: 'bell', text: s.t("You're all caught up.", 'لا توجد إشعارات جديدة.'))
                          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              for (final (label, items) in [
                                (s.t('TODAY', 'اليوم'), today),
                                (s.t('EARLIER', 'سابقًا'), earlier),
                              ])
                                if (items.isNotEmpty) ...[
                                  SectionLabel(label),
                                  for (final n in items) ...[
                                    _NoteCard(n: n, unread: isUnread(n)),
                                    const SizedBox(height: 8),
                                  ],
                                  const SizedBox(height: 10),
                                ],
                            ]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.n, required this.unread});
  final AppNotification n;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    // Unread trip updates get the accent tone; unread promos the dark tone; the rest paper.
    final tone = !unread ? 'paper' : (n.kind == 'promo' ? 'dark' : 'accent');
    final dark = tone != 'paper';
    final fg = dark ? Colors.white : W.text;
    final iconBg = switch (tone) {
      'accent' => s.accent,
      'dark' => const Color(0x1FFFFFFF),
      _ => W.surface2,
    };
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? W.text : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: dark ? null : Border.all(color: W.border, width: 0.5),
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        if (tone == 'accent') PositionedDirectional(top: -56, end: -46, child: AccentGlow(color: s.accent, size: 180)),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)),
            child: WIcon(_iconFor(n.kind), size: 16, strokeWidth: 1.7, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(n.title, style: W.sans(size: 14, weight: FontWeight.w500, color: fg))),
                if (unread) ...[
                  const SizedBox(width: 6),
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: s.accent, shape: BoxShape.circle)),
                ],
              ]),
              if (n.body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(n.body, style: W.sans(size: 12.5, color: fg.withValues(alpha: 0.7), height: 1.5)),
              ],
              const SizedBox(height: 8),
              MonoLabel(timeAgo(n.createdAt, ar: s.ar), size: 9.5, spacing: 0.18, color: fg.withValues(alpha: 0.5)),
            ]),
          ),
        ]),
      ]),
    );
  }
}
