import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';

/// Rider ↔ driver chat for one trip. Route argument: the trip id.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final WasilhaBackend _backend = context.read<WasilhaBackend>();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String? _tripId;
  Stream<List<ChatMessage>>? _messages;
  Stream<Trip?>? _trip;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = ModalRoute.of(context)?.settings.arguments as String? ?? context.read<AppState>().activeTripId;
    if (id != null && id != _tripId) {
      _tripId = id;
      _messages = _backend.chat(id);
      _trip = _backend.watchTrip(id);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? quick]) async {
    final id = _tripId;
    final text = (quick ?? _input.text).trim();
    if (id == null || text.isEmpty) return;
    _input.clear();
    try {
      await _backend.sendMessage(id, text);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = _backend.uid ?? 'demo-user';
    return Scaffold(
      backgroundColor: W.screenBg,
      body: SafeArea(
        child: StreamBuilder<Trip?>(
          stream: _trip,
          builder: (context, tripSnap) {
            final trip = tripSnap.data;
            final iAmRider = trip == null || trip.riderId == me;
            final otherName = (trip == null ? null : (iAmRider ? trip.driverName : trip.riderName)) ?? s.t('Driver', 'السائق');
            final quick = iAmRider
                ? [s.t("I'm at the pickup point", 'أنا في نقطة الانطلاق'), s.t('Please call me', 'اتصل بي من فضلك'), s.t('How long?', 'كم دقيقة؟')]
                : [s.t("I've arrived", 'وصلت'), s.t('On my way', 'في الطريق'), s.t('Where exactly are you?', 'وين بالضبط؟')];
            return Column(children: [
              TopBar(
                title: otherName,
                trailing: Avatar(label: _initials(otherName), size: 40, tone: iAmRider ? 'cool' : 'warm'),
              ),
              Expanded(
                child: _tripId == null
                    ? Center(child: Text(s.t('No active trip', 'لا توجد رحلة نشطة'), style: W.sans(color: W.text2)))
                    : StreamBuilder<List<ChatMessage>>(
                        stream: _messages,
                        builder: (context, snap) {
                          final msgs = snap.data ?? const <ChatMessage>[];
                          if (msgs.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  const WIcon('chat', size: 28, color: W.text3),
                                  const SizedBox(height: 10),
                                  Text(
                                    s.t('Messages stay inside Wasilha — your number is never shared.',
                                        'الرسائل تبقى داخل وصلها — رقمك لا يُشارك أبداً.'),
                                    textAlign: TextAlign.center,
                                    style: W.sans(size: 13, color: W.text2),
                                  ),
                                ]),
                              ),
                            );
                          }
                          _toBottom();
                          return ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            itemCount: msgs.length,
                            itemBuilder: (_, i) => _Bubble(msg: msgs[i], mine: msgs[i].senderId == me, accent: s.accent),
                          );
                        },
                      ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final q in quick)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ActionChip(
                          label: Text(q, style: W.sans(size: 12.5)),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: W.border),
                          shape: const StadiumBorder(),
                          onPressed: () => _send(q),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Row(children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: W.border),
                      ),
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: W.sans(size: 14.5),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: s.t('Message', 'اكتب رسالة'),
                          hintStyle: W.sans(size: 14.5, color: W.text3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: s.accent, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const WIcon('arrow', size: 18, strokeWidth: 1.9, color: Colors.white),
                    ),
                  ),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final r = parts.take(2).map((p) => p[0]).join().toUpperCase();
    return r.isEmpty ? '?' : r;
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg, required this.mine, required this.accent});
  final ChatMessage msg;
  final bool mine;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = msg.createdAt;
    final time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: mine ? accent : Colors.white,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(18),
            topEnd: const Radius.circular(18),
            bottomStart: Radius.circular(mine ? 18 : 4),
            bottomEnd: Radius.circular(mine ? 4 : 18),
          ),
          border: mine ? null : Border.all(color: W.border, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(msg.text, style: W.sans(size: 14.5, color: mine ? Colors.white : W.text, height: 1.3)),
          const SizedBox(height: 3),
          Text(time, style: W.mono(size: 9, color: mine ? Colors.white70 : W.text3)),
        ]),
      ),
    );
  }
}
