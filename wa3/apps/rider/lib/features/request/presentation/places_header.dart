import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// Pickup and destination rows; tap either to change it.
class PlacesHeader extends StatelessWidget {
  const PlacesHeader({super.key, required this.pickup, required this.dropoff, required this.onPickup, required this.onDropoff});
  final Place? pickup;
  final Place dropoff;
  final VoidCallback onPickup;
  final VoidCallback onDropoff;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = pickup;
    final pickupText = p == null
        ? s.t('اختر نقطة الانطلاق', 'Choose your pickup point')
        : (p.label.isEmpty ? s.t('موقعي الحالي', 'My current location') : p.label);
    return Card(
      child: Column(children: [
        _row(context, MapColors.pickup, s.t('من', 'From'), pickupText, onPickup, missing: p == null),
        const Divider(indent: WSpace.lg, endIndent: WSpace.lg),
        _row(context, MapColors.dropoff, s.t('إلى', 'To'), dropoff.label, onDropoff),
      ]),
    );
  }

  Widget _row(BuildContext context, Color color, String caption, String text, VoidCallback onTap, {bool missing = false}) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      minTileHeight: WSpace.touch + 8,
      leading: Icon(Icons.circle, size: 14, color: color),
      title: Text(caption, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      subtitle: Text(text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(color: missing ? theme.colorScheme.primary : null)),
      trailing: Icon(Icons.edit_outlined, semanticLabel: context.s.t('تغيير', 'Change')),
    );
  }
}
