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

String txnIcon(String kind) => switch (kind) {
      'topup' => 'plus',
      'ride' => 'car',
      'food' => 'bowl',
      'parcel' => 'gift',
      'refund' => 'gift',
      'tip' => 'star',
      'delivery' => 'bag',
      _ => 'receipt',
    };

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _all = false;
  late final WasilhaBackend _backend = context.read<WasilhaBackend>();
  late final Stream<UserProfile?> _profile = _backend.profile();
  late final Stream<List<WalletTxn>> _txns = _backend.transactions();

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
            builder: (context, profSnap) {
              final p = profSnap.data;
              return StreamBuilder<List<WalletTxn>>(
                stream: _txns,
                builder: (context, txSnap) {
                  final txs = txSnap.data;
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 120),
                    children: [
                      AccountHeader(
                        title: s.t('WALLET · المحفظة', 'المحفظة · WALLET'),
                        onBack: () => context.tab('home'),
                        trailing: SquareBtn(icon: 'settings', onTap: () => context.tab('settings')),
                      ),
                      _Balance(profile: p, txs: txs),
                      _Actions(),
                      _VirtualCard(profile: p),
                      _Activity(
                        txs: txs,
                        showAll: _all,
                        onToggle: () => setState(() => _all = !_all),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const BottomNav(active: 'wallet'),
      ]),
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({required this.profile, required this.txs});
  final UserProfile? profile;
  final List<WalletTxn>? txs;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    final inThisMonth = (txs ?? const <WalletTxn>[])
        .where((t) => t.amount > 0 && t.createdAt.year == now.year && t.createdAt.month == now.month)
        .fold<int>(0, (a, t) => a + t.amount);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 28, 18, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        MonoLabel(s.t('AVAILABLE BALANCE', 'الرصيد المتاح'), spacing: 0.3),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: profile == null
                  ? Text('—', style: W.serif(size: 76, height: 0.95, letterSpacing: -0.035 * 76))
                  : Text(sdg(profile!.balance), style: W.serif(size: 76, height: 0.95, letterSpacing: -0.035 * 76)),
            ),
          ),
          const SizedBox(width: 6),
          Text(s.t('SDG', 'ج.س'), style: W.mono(size: 13, color: W.text2)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('محفظة وصلها', style: W.arSerif(size: 18, color: W.text2)),
          if (inThisMonth > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: s.accent.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(999)),
              child: Text(s.t('+ ${sdg(inThisMonth)} this month', '+ ${sdg(inThisMonth)} هذا الشهر'),
                  style: W.sans(size: 12, color: s.accent)),
            ),
        ]),
      ]),
    );
  }
}

class _Actions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    void soon() => snack(context, s.t('Coming soon', 'قريبًا'));
    final items = [
      ('plus', s.t('Top up', 'شحن'), true, () => context.go('topup')),
      ('arrow', s.t('Send', 'تحويل'), false, soon),
      ('receipt', s.t('Pay bill', 'دفع فاتورة'), false, soon),
      ('gift', s.t('Rewards', 'المكافآت'), false, soon),
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 20, 18, 0),
      child: Row(children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _ActionTile(icon: items[i].$1, label: items[i].$2, primary: items[i].$3, onTap: items[i].$4)),
        ],
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.primary, required this.onTap});
  final String icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<AppState>().accent;
    final fg = primary ? Colors.white : W.text;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: primary ? W.text : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: primary
              ? const [BoxShadow(color: Color(0x2E0A0908), blurRadius: 22, offset: Offset(0, 8))]
              : const [BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          if (primary) PositionedDirectional(top: -34, end: -20, child: AccentGlow(color: accent, size: 60, stop: 0.7)),
          Column(mainAxisSize: MainAxisSize.min, children: [
            WIcon(icon, size: 18, strokeWidth: 1.7, color: fg),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 11.5, color: fg)),
          ]),
        ]),
      ),
    );
  }
}

class _VirtualCard extends StatelessWidget {
  const _VirtualCard({required this.profile});
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final last4 = ((profile?.uid.hashCode ?? 4421).abs() % 10000).toString().padLeft(4, '0');
    final name = (profile?.name.isNotEmpty ?? false) ? profile!.name : s.t('Wasilha rider', 'راكب وصلها');
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 20, 18, 0),
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: W.text,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x380A0908), blurRadius: 30, offset: Offset(0, 14))],
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          PositionedDirectional(top: -56, end: -58, child: AccentGlow(color: s.accent, size: 200)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('WASILHA CARD', style: W.mono(size: 9, color: const Color(0x8CFFFFFF), letterSpacing: 0.3)),
                  const SizedBox(height: 8),
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.serif(size: 22, color: Colors.white, letterSpacing: -0.22)),
                ]),
              ),
              Text('وصلها', style: W.arSerif(size: 28, color: Colors.white, height: 1)),
            ]),
            const SizedBox(height: 20),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text('•••• •••• •••• $last4', style: W.mono(size: 16, color: Colors.white, letterSpacing: 0.22)),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Text('EXP 09/29', style: W.mono(size: 10, color: const Color(0x99FFFFFF))),
              const Spacer(),
              Text('VIRTUAL · NFC', style: W.mono(size: 10, color: const Color(0x99FFFFFF))),
            ]),
          ]),
        ]),
      ),
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity({required this.txs, required this.showAll, required this.onToggle});
  final List<WalletTxn>? txs;
  final bool showAll;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = txs;
    final shown = list == null ? const <WalletTxn>[] : (showAll ? list : list.take(6).toList());
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 24, 18, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Expanded(child: MonoLabel(s.t('RECENT ACTIVITY', 'النشاط الأخير'), spacing: 0.3)),
            if (list != null && list.length > 6)
              GestureDetector(
                onTap: onToggle,
                child: Text(showAll ? s.t('Show less', 'عرض أقل') : s.t('See all', 'عرض الكل'),
                    style: W.sans(size: 12, color: s.accent)),
              ),
          ]),
        ),
        if (list == null)
          const Loading()
        else if (list.isEmpty)
          ListCard(children: [EmptyNote(icon: 'wallet', text: s.t('No activity yet — top up to get started.', 'لا يوجد نشاط بعد — اشحن رصيدك للبدء.'))])
        else
          ListCard(children: [
            for (var i = 0; i < shown.length; i++) _TxnRow(t: shown[i], last: i == shown.length - 1),
          ]),
      ]),
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.t, required this.last});
  final WalletTxn t;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final add = t.amount > 0;
    final c = add ? W.success : W.text;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: W.border, width: 0.5)),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: add ? W.success.withValues(alpha: 0.08) : W.surface2,
            borderRadius: BorderRadius.circular(11),
          ),
          child: WIcon(txnIcon(t.kind), size: 16, strokeWidth: 1.7, color: c),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 13.5, weight: FontWeight.w500)),
            const SizedBox(height: 2),
            MonoLabel(whenLabel(t.createdAt, s.ar), spacing: 0.1),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${add ? '+' : '−'}${sdg(t.amount.abs())}', style: W.mono(size: 14, weight: FontWeight.w600, color: c, letterSpacing: 0)),
          Text(s.t('SDG', 'ج.س'), style: W.mono(size: 9, color: W.text3, letterSpacing: 0.18)),
        ]),
      ]),
    );
  }
}
