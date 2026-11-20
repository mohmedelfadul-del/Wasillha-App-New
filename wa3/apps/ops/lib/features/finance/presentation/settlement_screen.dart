import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';
import '../../../app/widgets/failure.dart';
import '../../../app/widgets/fields.dart';
import '../../people/domain/people_repository.dart';
import 'driver_money_panel.dart';

/// Pick a driver (exact id or phone), then see and settle their cash commission.
class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key, this.initialDriverId});
  final String? initialDriverId;
  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  final _q = TextEditingController();
  DriverProfile? _driver;
  List<DriverProfile>? _matches;
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    final id = widget.initialDriverId;
    if (id != null && id.isNotEmpty) {
      _q.text = id;
      WidgetsBinding.instance.addPostFrameCallback((_) => _find());
    }
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final q = _q.text.trim();
    if (q.isEmpty) return;
    final people = context.services.people;
    setState(() {
      _busy = true;
      _error = null;
      _matches = null;
      _driver = null;
    });
    try {
      final phone = normalizePhone(q);
      final found = <DriverProfile>[];
      if (phone != null) {
        found.addAll(await people.driversByPhone(phone.startsWith('+') ? phone : '+$phone'));
        if (found.isEmpty && !phone.startsWith('+')) found.addAll(await people.driversByPhone(phone));
      }
      if (found.isEmpty) {
        final d = await people.driver(q);
        if (d != null) found.add(d);
      }
      if (!mounted) return;
      setState(() {
        _matches = found;
        if (found.length == 1) _driver = found.first;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return PageBody(maxWidth: 760, children: [
      TextField(
        controller: _q,
        textDirection: TextDirection.ltr,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _find(),
        decoration: InputDecoration(
          labelText: s.t('معرّف السائق أو رقم هاتفه', 'Driver id or phone number'),
          suffixIcon: IconButton(tooltip: s.t('بحث', 'Find'), icon: const Icon(Icons.search), onPressed: _busy ? null : _find),
        ),
      ),
      const SizedBox(height: WSpace.md),
      if (_busy) Semantics(label: s.loading, child: const LinearProgressIndicator()),
      if (_error != null) WBanner(tone: Tone.error, text: describeFailure(s, _error is ApiFailure ? _error as ApiFailure : ApiFailure('internal', '$_error'))),
      if (_matches != null && _matches!.isEmpty) WStateView.empty(icon: Icons.person_search, title: s.t('لا يوجد سائق بهذا المعرّف أو الرقم', 'No driver with that id or phone')),
      if (_matches != null && _matches!.length > 1 && _driver == null)
        for (final d in _matches!)
          ListTile(contentPadding: EdgeInsets.zero, title: Text(d.name), subtitle: Text('${ltr(d.phone)} · ${ltr(shortId(d.uid))}'), onTap: () => setState(() => _driver = d)),
      if (_driver != null) DriverMoneyPanel(key: ValueKey(_driver!.uid), driver: _driver!),
    ]);
  }
}
