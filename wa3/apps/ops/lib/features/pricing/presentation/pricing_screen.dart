import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';
import '../../../app/widgets/fields.dart';
import '../../../app/widgets/live_view.dart';
import '../domain/pricing_repository.dart';
import 'pricing_form.dart';

/// Per zone × category pricing (admin only; the shell gates the route).
class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});
  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  String? _zoneId;
  Category _category = Category.economy;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final repo = context.services.pricing;
    return LiveView<List<Zone>>(
      open: repo.zones,
      isEmpty: (z) => z.isEmpty,
      empty: (_) => WStateView.empty(icon: Icons.map_outlined, title: s.t('لا توجد مناطق خدمة مُعدّة', 'No service zones are configured')),
      builder: (context, zones) {
        final zone = zones.firstWhere((z) => z.id == _zoneId, orElse: () => zones.first);
        return PageBody(maxWidth: 720, children: [
          DropdownButtonFormField<String>(
            initialValue: zone.id,
            isExpanded: true,
            decoration: InputDecoration(labelText: s.t('المنطقة', 'Zone')),
            items: [for (final z in zones) DropdownMenuItem(value: z.id, child: Text('${z.name}${z.active ? '' : s.t(' (غير نشطة)', ' (inactive)')}', overflow: TextOverflow.ellipsis))],
            onChanged: (v) => setState(() => _zoneId = v),
          ),
          const SizedBox(height: WSpace.md),
          Text(s.t('الفئة', 'Category')),
          const SizedBox(height: WSpace.xs),
          Wrap(spacing: WSpace.sm, runSpacing: WSpace.sm, children: [
            for (final c in Category.values)
              ChoiceChip(label: Text(s.category(c)), selected: c == _category, onSelected: (_) => setState(() => _category = c)),
          ]),
          SectionTitle('${zone.name} · ${s.category(_category)}'),
          LiveSection<PricingRecord?>(
            key: ValueKey('${zone.id}__${_category.name}'),
            open: () => repo.watch(zone.id, _category),
            builder: (context, current) => PricingForm(
              key: ValueKey('form-${zone.id}__${_category.name}'),
              zoneId: zone.id,
              category: _category,
              current: current,
            ),
          ),
        ]);
      },
    );
  }
}
