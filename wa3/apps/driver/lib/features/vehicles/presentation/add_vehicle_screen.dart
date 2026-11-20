import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';
import '../domain/vehicle_repository.dart';
import 'vehicle_detail_screen.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key, required this.uid});
  final String uid;
  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _form = GlobalKey<FormState>();
  final _make = TextEditingController(), _model = TextEditingController(), _color = TextEditingController();
  final _plate = TextEditingController(), _year = TextEditingController();
  Category? _category;
  bool _categoryMissing = false;
  IntentKey? _key;

  @override
  void dispose() {
    for (final c in [_make, _model, _color, _plate, _year]) {
      c.dispose();
    }
    super.dispose();
  }

  String? Function(String?) _required(int max) => (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return context.s.t('هذا الحقل مطلوب', 'This field is required');
        if (t.length > max) return context.s.t('طويل جداً', 'Too long');
        return null;
      };

  String? _validYear(String? v) {
    final y = int.tryParse((v ?? '').trim());
    final max = context.services.clock().year + 1;
    if (y == null || y < 1980 || y > max) return context.s.t('اكتب سنة بين 1980 و$max', 'Enter a year between 1980 and $max');
    return null;
  }

  Future<void> _submit() async {
    final ok = _form.currentState!.validate();
    setState(() => _categoryMissing = _category == null);
    if (!ok || _category == null) return;
    _key ??= IntentKey.generate();
    final id = await context.services.vehicles.add(
      NewVehicle(category: _category!, make: _make.text.trim(), model: _model.text.trim(), color: _color.text.trim(), plate: _plate.text.trim(), year: int.parse(_year.text.trim())),
      key: _key!,
    );
    if (!mounted) return;
    final v = Vehicle(id: id, category: _category!, make: _make.text.trim(), model: _model.text.trim(), color: _color.text.trim(), plate: _plate.text.trim().toUpperCase(), year: int.parse(_year.text.trim()), status: 'pending');
    showSuccess(context, context.s.t('أُضيفت المركبة. ارفع وثائقها الآن.', 'Vehicle added. Now upload its documents.'));
    await Navigator.pushReplacement(context, MaterialPageRoute<void>(builder: (_) => VehicleDetailScreen(uid: widget.uid, vehicle: v)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('أضف مركبة', 'Add vehicle'))),
      body: Form(
        key: _form,
        onChanged: () => _key = null,
        child: ListView(padding: const EdgeInsets.all(WSpace.lg), children: [
          Text(s.t('الفئة', 'Category'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: WSpace.sm),
          Wrap(spacing: WSpace.sm, runSpacing: WSpace.sm, children: [
            for (final c in Category.values)
              ChoiceChip(
                label: Text(s.category(c)),
                selected: _category == c,
                onSelected: (_) => setState(() {
                  _category = c;
                  _categoryMissing = false;
                  _key = null;
                }),
              ),
          ]),
          if (_categoryMissing)
            Padding(
              padding: const EdgeInsets.only(top: WSpace.xs),
              child: Text(s.t('اختر فئة المركبة', 'Choose the vehicle category'), style: const TextStyle(color: WColors.error)),
            ),
          const SizedBox(height: WSpace.lg),
          TextFormField(controller: _make, decoration: InputDecoration(labelText: s.t('الشركة المصنّعة', 'Make'), hintText: 'Toyota'), validator: _required(40)),
          const SizedBox(height: WSpace.md),
          TextFormField(controller: _model, decoration: InputDecoration(labelText: s.t('الطراز', 'Model'), hintText: 'Corolla'), validator: _required(40)),
          const SizedBox(height: WSpace.md),
          TextFormField(controller: _color, decoration: InputDecoration(labelText: s.t('اللون', 'Color')), validator: _required(30)),
          const SizedBox(height: WSpace.md),
          TextFormField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: s.t('رقم اللوحة', 'Plate number')),
            validator: _required(20),
          ),
          const SizedBox(height: WSpace.md),
          TextFormField(
            controller: _year,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            decoration: InputDecoration(labelText: s.t('سنة الصنع', 'Year')),
            validator: _validYear,
          ),
          const SizedBox(height: WSpace.xl),
          PrimaryAction(label: s.t('أضف المركبة', 'Add vehicle'), onPressed: _submit),
        ]),
      ),
    );
  }
}
