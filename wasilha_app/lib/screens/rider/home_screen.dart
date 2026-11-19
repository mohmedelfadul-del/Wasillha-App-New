import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/location.dart';
import '../../core/nav.dart';
import '../../data/backend.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/map_view.dart';
import '../../widgets/service_cards.dart';
import '../../widgets/w_icon.dart';

/// 05 — Rider home: live map, "Where to?", saved places and the service cards.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _initial = 0.62;

  late final WasilhaBackend _backend = context.read<WasilhaBackend>();
  late final Stream<UserProfile?> _profile = _backend.profile();
  late final Stream<List<AppNotification>> _notes = _backend.notifications();
  late final Stream<List<Place>> _saved = _backend.savedPlaces();
  late final Stream<List<StoreOrder>> _orders = _backend.myOrders();

  String? _tripId;
  Stream<Trip?>? _trip;
  final _extent = ValueNotifier<double>(_initial);

  @override
  void initState() {
    super.initState();
    _locate();
  }

  /// Use the device GPS as pickup the first time Home opens (falls back silently).
  Future<void> _locate() async {
    final s = context.read<AppState>();
    if (s.pickup.id == 'gps') return;
    final here = await LocationService.currentPlace();
    if (here != null && mounted) s.setPickup(here);
  }

  Stream<Trip?>? _tripStream(String? id) {
    if (id != _tripId) {
      _tripId = id;
      _trip = id == null ? null : _backend.watchTrip(id);
    }
    return _trip;
  }

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  // ── Routing ───────────────────────────────────────────────
  void _ride(ServiceType t) {
    context.read<AppState>().chooseService(t);
    context.go('search');
  }

  void _openTrip(Trip? trip) {
    if (trip == null || !trip.isActive) {
      context.go('history');
    } else {
      context.go(trip.status == TripStatus.requested ? 'offer' : 'tracking');
    }
  }

  void _onService(String id, Trip? activeTrip) {
    switch (id) {
      case 'raksha':
        _ride(ServiceType.raksha);
      case 'moto':
      case 'bike':
        _ride(ServiceType.moto);
      case 'car':
        _ride(ServiceType.car);
      case 'delivery':
      case 'parcel':
        context.go('parcel');
      case 'food':
      case 'store':
        context.go('food');
      case 'tracking':
        _openTrip(activeTrip);
      default: // schedule & anything else → plan a ride
        _ride(ServiceType.car);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final trip$ = _tripStream(s.activeTripId);
    return Scaffold(
      backgroundColor: W.screenBg,
      body: StreamBuilder<Trip?>(
        stream: trip$,
        builder: (context, tripSnap) {
          final trip = trip$ == null ? null : tripSnap.data;
          final activeTrip = trip != null && trip.isActive ? trip : null;
          return LayoutBuilder(builder: (context, box) {
            return Stack(children: [
              const Positioned.fill(child: WMap(drivers: 5, pulse: true)),
              _TopBar(notes: _notes, activeTrip: activeTrip, onTrip: () => _openTrip(activeTrip)),
              ValueListenableBuilder<double>(
                valueListenable: _extent,
                builder: (context, e, child) => Positioned(
                  left: 16,
                  right: 16,
                  bottom: e * box.maxHeight + 12,
                  child: Opacity(opacity: e > 0.8 ? 0 : 1, child: child),
                ),
                child: const _MapControls(),
              ),
              NotificationListener<DraggableScrollableNotification>(
                onNotification: (n) {
                  _extent.value = n.extent;
                  return false;
                },
                child: DraggableScrollableSheet(
                  initialChildSize: _initial,
                  minChildSize: 0.38,
                  maxChildSize: 0.9,
                  snap: true,
                  snapSizes: const [_initial],
                  builder: (context, scroll) => _Sheet(
                    scroll: scroll,
                    profile: _profile,
                    saved: _saved,
                    orders: _orders,
                    activeTrip: activeTrip,
                    onService: (id) => _onService(id, activeTrip),
                  ),
                ),
              ),
              const BottomNav(active: 'home'),
            ]);
          });
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top bar: location pill, bell, active-trip banner.
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.notes, required this.activeTrip, required this.onTrip});
  final Stream<List<AppNotification>> notes;
  final Trip? activeTrip;
  final VoidCallback onTrip;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('search'),
                  child: Glass(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 14, 10),
                    child: Row(children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: W.success,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Color(0x2E1F8A5B), spreadRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          MonoLabel(s.t('Current location', 'الموقع الحالي'), size: 8.5),
                          const SizedBox(height: 1),
                          Text(
                            [s.pickup.label(s.ar), if (s.pickup.area.isNotEmpty) s.pickup.area].join(s.ar ? '، ' : ', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: W.sans(size: 13.5, weight: FontWeight.w500),
                          ),
                        ]),
                      ),
                      const WIcon('chevDown', size: 14, color: W.text2),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              StreamBuilder<List<AppNotification>>(
                stream: notes,
                builder: (context, snap) {
                  final unread = (snap.data ?? const []).where((n) => !n.read).length;
                  return Semantics(
                    label: s.t('Notifications, $unread unread', 'الإشعارات، $unread غير مقروءة'),
                    child: CircleBtn(
                      icon: 'bell',
                      glass: true,
                      size: 44,
                      badge: unread > 0,
                      onTap: () => context.go('notifications'),
                    ),
                  );
                },
              ),
            ]),
            if (activeTrip != null) ...[
              const SizedBox(height: 10),
              _TripBanner(trip: activeTrip!, onTap: onTrip),
            ],
          ]),
        ),
      ),
    );
  }
}

class _TripBanner extends StatelessWidget {
  const _TripBanner({required this.trip, required this.onTap});
  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final status = switch (trip.status) {
      TripStatus.requested => s.t('Collecting driver offers', 'نجمع عروض السائقين'),
      TripStatus.accepted => s.t('Driver on the way', 'السائق في الطريق'),
      TripStatus.arriving => s.t('Driver arriving', 'السائق وصل تقريباً'),
      TripStatus.inProgress => s.t('On your way to ${trip.dropoff.label(false)}', 'في الطريق إلى ${trip.dropoff.label(true)}'),
      _ => '',
    };
    return GestureDetector(
      onTap: onTap,
      child: Glass(
        dark: true,
        radius: 18,
        padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 14, 8),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: s.accent, shape: BoxShape.circle),
            child: WIcon(trip.service.icon, size: 17, strokeWidth: 1.8, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              MonoLabel(s.t('Active trip', 'رحلة نشطة'), color: const Color(0x99FFFFFF), size: 8.5),
              const SizedBox(height: 2),
              Text(status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: W.sans(size: 13, weight: FontWeight.w500, color: Colors.white)),
            ]),
          ),
          Text('${sdg(trip.fare)} ${s.t('SDG', 'ج.س')}', style: W.mono(size: 10.5, color: const Color(0xCCFFFFFF), letterSpacing: 0.08)),
          const SizedBox(width: 8),
          const WIcon('chevron', size: 14, color: Colors.white),
        ]),
      ),
    );
  }
}

/// Promo strip + recenter button, floating just above the sheet.
class _MapControls extends StatelessWidget {
  const _MapControls();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Flexible(
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 12, 8),
          decoration: BoxDecoration(
            color: W.text,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [BoxShadow(color: Color(0x330A0908), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: s.accent, shape: BoxShape.circle),
              child: const WIcon('gift', size: 14, strokeWidth: 1.8, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(s.t('20% off your next 3 rides', 'خصم ٢٠٪ على رحلاتك الـ٣ القادمة'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: W.sans(size: 12, color: Colors.white)),
            ),
          ]),
        ),
      ),
      const Spacer(),
      GestureDetector(
        onTap: () {
          s.setPickup(Catalog.defaultPickup);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: W.text,
            duration: const Duration(seconds: 2),
            content: Text(s.t('Pickup reset to ${Catalog.defaultPickup.label(false)}',
                'تم ضبط نقطة الانطلاق إلى ${Catalog.defaultPickup.label(true)}')),
          ));
        },
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x1F140F1E), blurRadius: 22, offset: Offset(0, 8))],
          ),
          child: const WIcon('target', size: 18, strokeWidth: 1.7, color: W.text),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom sheet
// ─────────────────────────────────────────────────────────────
class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.scroll,
    required this.profile,
    required this.saved,
    required this.orders,
    required this.activeTrip,
    required this.onService,
  });

  final ScrollController scroll;
  final Stream<UserProfile?> profile;
  final Stream<List<Place>> saved;
  final Stream<List<StoreOrder>> orders;
  final Trip? activeTrip;
  final ValueChanged<String> onService;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Container(
      decoration: const BoxDecoration(
        color: W.screenBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x14140F1E), blurRadius: 30, offset: Offset(0, -8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: StreamBuilder<UserProfile?>(
        stream: profile,
        builder: (context, profSnap) {
          final me = profSnap.data;
          return ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(18, 12, 18, 110 + MediaQuery.paddingOf(context).bottom),
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: W.border2, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              _Greeting(name: me?.firstName ?? ''),
              const SizedBox(height: 14),
              const _WhereTo(),
              const SizedBox(height: 12),
              _SavedChips(saved: saved),
              const SizedBox(height: 22),
              MonoLabel(s.t('Services', 'الخدمات'), size: 9.5, spacing: 0.3),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: s.t('How would you like to ', 'كيف تحب ')),
                  TextSpan(text: s.t('move?', 'تتحرك؟'), style: TextStyle(color: s.accent)),
                ]),
                style: s.ar ? W.arSerif(size: 24) : W.serif(size: 24, height: 1.1),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<StoreOrder>>(
                stream: orders,
                builder: (context, oSnap) {
                  final activeOrders = (oSnap.data ?? const <StoreOrder>[])
                      .where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.declined)
                      .length;
                  return _Services(
                    activeCount: activeOrders + (activeTrip != null ? 1 : 0),
                    onService: onService,
                  );
                },
              ),
              const SizedBox(height: 22),
              MonoLabel(s.t('Promotions', 'العروض'), size: 9.5, spacing: 0.3),
              const SizedBox(height: 12),
              const _Promos(),
              const SizedBox(height: 18),
              _WalletCard(balance: me?.balance),
            ],
          );
        },
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final h = DateTime.now().hour;
    final hello = h < 12
        ? s.t('Good morning', 'صباح الخير')
        : h < 18
            ? s.t('Good afternoon', 'مساء الخير')
            : s.t('Good evening', 'مساء النور');
    final text = name.isEmpty ? hello : '$hello, $name';
    return Text(text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: s.ar ? W.arSerif(size: 26) : W.serif(size: 28, height: 1.05));
  }
}

class _WhereTo extends StatelessWidget {
  const _WhereTo();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => context.go('search'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: W.text,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0x290A0908), blurRadius: 28, offset: Offset(0, 10))],
          ),
          child: Row(children: [
            const WIcon('search', size: 18, strokeWidth: 1.7, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.t('Where to?', 'إلى أين؟'), style: W.sans(size: 15, weight: FontWeight.w500, color: Colors.white)),
                const SizedBox(height: 2),
                MonoLabel(s.t('Search any destination', 'ابحث عن وجهتك'), color: const Color(0x8CFFFFFF), spacing: 0.18),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const WIcon('clock', size: 12, strokeWidth: 1.8, color: Colors.white),
                const SizedBox(width: 4),
                Text(s.t('Now', 'الآن'), style: W.sans(size: 11, color: Colors.white)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SavedChips extends StatelessWidget {
  const _SavedChips({required this.saved});
  final Stream<List<Place>> saved;

  static String _icon(Place p) {
    if (p.kind == 'home') return 'home';
    if (p.kind == 'work') return 'work';
    if (p.name.toLowerCase().contains('airport')) return 'plane';
    return 'pin';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return SizedBox(
      height: 36,
      child: StreamBuilder<List<Place>>(
        stream: saved,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.6)),
            );
          }
          final places = snap.data!;
          return ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final p in places) ...[
                _Chip(
                  icon: _icon(p),
                  title: p.label(s.ar),
                  detail: p.area,
                  onTap: () {
                    s.setDropoff(p);
                    context.go('booking');
                  },
                ),
                const SizedBox(width: 8),
              ],
              _Chip(
                icon: places.isEmpty ? 'plus' : 'star',
                title: places.isEmpty ? s.t('Add a place', 'أضف مكاناً') : s.t('Saved', 'المحفوظة'),
                onTap: () => context.go('saved'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.title, this.detail = '', required this.onTap});
  final String icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 14, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: W.border, width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          WIcon(icon, size: 14, strokeWidth: 1.7, color: W.text),
          const SizedBox(width: 8),
          Text(title, style: W.sans(size: 12.5, weight: FontWeight.w500)),
          if (detail.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text('· $detail', style: W.sans(size: 11, color: W.text3)),
          ],
        ]),
      ),
    );
  }
}

class _Services extends StatelessWidget {
  const _Services({required this.activeCount, required this.onService});
  final int activeCount;
  final ValueChanged<String> onService;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.cardLayout == 'pairs') {
      var foodFrom = 1 << 30;
      for (final r in Catalog.restaurants) {
        for (final m in r.menu) {
          if (m.price < foodFrom) foodFrom = m.price;
        }
      }
      if (foodFrom == 1 << 30) foodFrom = ServiceType.food.base;
      return ConnectedPairsPuzzle(
        prices: PairPrices(
          raksha: s.suggestedFare(ServiceType.raksha),
          moto: s.suggestedFare(ServiceType.moto),
          car: s.suggestedFare(ServiceType.car),
          delivery: s.suggestedFare(ServiceType.delivery),
          foodFrom: foodFrom,
        ),
        activeCount: activeCount,
        onTap: onService,
      );
    }

    final services = [
      ('raksha', 'raksha', s.t('Raksha', 'ركشة'), s.t('2 min away', 'على بعد ٢ دقيقة'), true),
      ('car', 'car', s.t('Car', 'سيارة'), s.t('3 min away', 'على بعد ٣ دقائق'), false),
      ('moto', 'bike', s.t('Motorcycle', 'موتر'), s.t('1 min away', 'على بعد دقيقة'), false),
      ('delivery', 'bag', s.t('Delivery', 'توصيل'), s.t('Send a parcel', 'أرسل طرداً'), false),
      ('food', 'bowl', s.t('Food', 'طعام'), s.t('25–40 min', '٢٥–٤٠ دقيقة'), false),
      ('schedule', 'clock', s.t('Schedule', 'مجدول'), s.t('Book later', 'احجز لاحقاً'), false),
    ];

    if (s.cardLayout == 'grid') {
      return LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 16) / 3;
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (id, icon, name, sub, primary) in services)
            SizedBox(
              width: w,
              child: ServiceCard(icon: icon, name: name, sub: sub, primary: primary, onTap: () => onService(id)),
            ),
        ]);
      });
    }

    return Column(children: [
      for (final (id, icon, name, sub, primary) in services) ...[
        ServiceCard(
          icon: icon,
          name: name,
          sub: sub,
          primary: primary,
          layout: ServiceCardLayout.row,
          onTap: () => onService(id),
        ),
        const SizedBox(height: 8),
      ],
    ]);
  }
}

class _Promos extends StatelessWidget {
  const _Promos();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final promos = [
      (s.t('Ramadan rides', 'مشاوير رمضان'), s.t('500 SDG off after sunset', 'خصم ٥٠٠ ج.س بعد المغرب'), s.t('Limited', 'لفترة محدودة'), 'dark'),
      (s.t('Refer a friend', 'ادعُ صديقاً'), s.t('Both get 1,000 SDG credit', 'رصيد ١٬٠٠٠ ج.س لكل منكما'), s.t('Evergreen', 'دائم'), 'paper'),
      (s.t('Airport flat fare', 'سعر ثابت للمطار'), s.t('KRT terminals · 3,800 SDG', 'مطار الخرطوم · ٣٬٨٠٠ ج.س'), s.t('New', 'جديد'), 'accent'),
    ];
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: promos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (title, sub, tag, tone) = promos[i];
          final fg = tone == 'paper' ? W.text : Colors.white;
          return Container(
            width: 240,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: tone == 'dark' ? W.text : tone == 'accent' ? s.accent : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: tone == 'paper' ? Border.all(color: W.border, width: 0.5) : null,
              boxShadow: const [BoxShadow(color: Color(0x14140F1E), blurRadius: 22, offset: Offset(0, 8))],
              gradient: tone == 'dark'
                  ? RadialGradient(
                      center: const AlignmentDirectional(1.1, -1.2).resolve(Directionality.of(context)),
                      radius: 0.9,
                      colors: [s.accent.withValues(alpha: 0.38), W.text],
                      stops: const [0, 0.7],
                    )
                  : null,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              MonoLabel(tag, color: fg.withValues(alpha: 0.7), size: 9, spacing: 0.24),
              const SizedBox(height: 10),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: s.ar ? W.arSerif(size: 20, color: fg) : W.serif(size: 22, color: fg, height: 1.1)),
              const SizedBox(height: 4),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 12, color: fg.withValues(alpha: 0.7))),
            ]),
          );
        },
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.balance});
  final int? balance;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return GestureDetector(
      onTap: () => context.tab('wallet'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: W.border, width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: s.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
            child: WIcon('wallet', size: 20, strokeWidth: 1.7, color: s.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              MonoLabel(s.t('Wallet', 'المحفظة'), size: 9, spacing: 0.24),
              const SizedBox(height: 2),
              balance == null
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.6))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(sdg(balance!), style: W.serif(size: 26)),
                        const SizedBox(width: 5),
                        Text(s.t('SDG', 'ج.س'), style: W.mono(size: 10, color: W.text2)),
                      ],
                    ),
            ]),
          ),
          GestureDetector(
            onTap: () => context.go('topup'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: W.surface2, borderRadius: BorderRadius.circular(999)),
              child: Text(s.t('Top up', 'اشحن'), style: W.sans(size: 12, weight: FontWeight.w500)),
            ),
          ),
        ]),
      ),
    );
  }
}
