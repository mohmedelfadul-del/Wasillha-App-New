import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../features/account/domain/driver_repository.dart';
import '../features/account/presentation/account_screen.dart';
import '../features/availability/application/availability_controller.dart';
import '../features/availability/presentation/availability_screen.dart';
import '../features/earnings/presentation/earnings_screen.dart';
import '../features/trip/presentation/active_trip_screen.dart';
import 'live.dart';
import 'services.dart';

/// Signed-in, registered driver. When the server sets activeTripId the trip
/// takes over the screen automatically, and stays until the driver closes
/// the finished trip (so they can rate the rider).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.live});
  final Live<DriverState> live;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final AvailabilityController _availability = AvailabilityController(
    uid: widget.live.data.profile.uid,
    driverRepo: context.services.driver,
    location: context.services.location,
    clock: context.services.clock,
  );
  int _tab = 0;
  String? _focusTripId;

  @override
  void initState() {
    super.initState();
    _focusTripId = widget.live.data.profile.activeTripId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _availability.onDriver(widget.live.data);
    });
  }

  @override
  void didUpdateWidget(HomeShell old) {
    super.didUpdateWidget(old);
    final active = widget.live.data.profile.activeTripId;
    final popToRoot = active != null && active != _focusTripId;
    if (popToRoot) _focusTripId = active;
    // Side effects after the frame: they notify listeners.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (popToRoot) Navigator.of(context).popUntil((r) => r.isFirst);
      _availability.onDriver(widget.live.data);
    });
  }

  @override
  void dispose() {
    _availability.dispose();
    super.dispose();
  }

  void _closeTrip() {
    if (widget.live.data.profile.activeTripId == _focusTripId) return;
    setState(() => _focusTripId = null);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final focus = _focusTripId;
    if (focus != null) return ActiveTripScreen(key: ValueKey(focus), tripId: focus, onDone: _closeTrip);
    final body = switch (_tab) {
      0 => AvailabilityScreen(live: widget.live, controller: _availability),
      1 => const EarningsScreen(),
      _ => AccountScreen(driver: widget.live.data),
    };
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.power_settings_new), label: s.t('العمل', 'Work')),
          NavigationDestination(icon: const Icon(Icons.payments_outlined), label: s.t('الأرباح', 'Earnings')),
          NavigationDestination(icon: const Icon(Icons.person_outline), label: s.t('حسابي', 'Account')),
        ],
      ),
    );
  }
}
