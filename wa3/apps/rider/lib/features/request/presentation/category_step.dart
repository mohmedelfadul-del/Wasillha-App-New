import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

IconData categoryIcon(Category c) => switch (c) {
      Category.rickshaw => Icons.electric_rickshaw,
      Category.motorbike => Icons.two_wheeler,
      Category.economy => Icons.directions_car_outlined,
      Category.comfort => Icons.local_taxi_outlined,
      Category.family => Icons.airport_shuttle_outlined,
    };

/// Vehicle category choice. Prices come from the server after choosing.
class CategoryStep extends StatelessWidget {
  const CategoryStep({super.key, required this.selected, required this.onSelect, this.enabled = true});
  final Category? selected;
  final ValueChanged<Category> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(s.t('نوع المركبة', 'Vehicle type'), style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: WSpace.sm),
      RadioGroup<Category>(
        groupValue: selected,
        onChanged: (c) {
          if (enabled && c != null) onSelect(c);
        },
        child: Column(children: [
          for (final c in Category.values)
            RadioListTile<Category>(
              value: c,
              enabled: enabled,
              contentPadding: EdgeInsets.zero,
              title: Row(children: [
                Icon(categoryIcon(c)),
                const SizedBox(width: WSpace.md),
                Flexible(child: Text(s.category(c))),
              ]),
            ),
        ]),
      ),
    ]);
  }
}
