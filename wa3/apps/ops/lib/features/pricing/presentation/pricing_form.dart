import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';
import '../../../app/widgets/failure.dart';
import '../../../app/widgets/fields.dart';
import '../../auth/application/session_controller.dart';
import '../domain/pricing_repository.dart';
import '../domain/pricing_validation.dart';

class PricingForm extends StatefulWidget {
  const PricingForm({super.key, required this.zoneId, required this.category, required this.current});
  final String zoneId;
  final Category category;
  final PricingRecord? current;
  @override
  State<PricingForm> createState() => _PricingFormState();
}

class _PricingFormState extends State<PricingForm> {
  final _c = {for (final f in PricingField.values) f: TextEditingController()};
  final _reason = TextEditingController();
  bool _enabled = true;
  int? _loadedVersion;
  Map<PricingField, PricingError> _errors = const {};
  bool _reasonMissing = false;

  @override
  void initState() {
    super.initState();
    _load(widget.current);
  }

  void _load(PricingRecord? p) {
    _loadedVersion = p?.version;
    _enabled = p?.enabled ?? true;
    String v(int? x) => x?.toString() ?? '';
    _c[PricingField.baseFare]!.text = v(p?.baseFare);
    _c[PricingField.perKm]!.text = v(p?.perKm);
    _c[PricingField.perMinute]!.text = v(p?.perMinute);
    _c[PricingField.minFare]!.text = v(p?.minFare);
    _c[PricingField.maxFare]!.text = v(p?.maxFare);
    _c[PricingField.belowPct]!.text = p == null ? '' : pctText(p.belowReferencePct);
    _c[PricingField.abovePct]!.text = p == null ? '' : pctText(p.aboveReferencePct);
    _c[PricingField.commissionPct]!.text = p == null ? '' : bpsText(p.commissionBps);
    _errors = const {};
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    _reason.dispose();
    super.dispose();
  }

  String _label(S s, PricingField f) => switch (f) {
        PricingField.baseFare => s.t('الأجرة الأساسية (ج.س)', 'Base fare (SDG)'),
        PricingField.perKm => s.t('لكل كيلومتر (ج.س)', 'Per km (SDG)'),
        PricingField.perMinute => s.t('لكل دقيقة (ج.س)', 'Per minute (SDG)'),
        PricingField.minFare => s.t('أدنى أجرة (ج.س)', 'Minimum fare (SDG)'),
        PricingField.maxFare => s.t('أعلى أجرة (ج.س)', 'Maximum fare (SDG)'),
        PricingField.belowPct => s.t('أقل من المرجعي حتى (٪)', 'Below reference up to (%)'),
        PricingField.abovePct => s.t('أعلى من المرجعي حتى (٪)', 'Above reference up to (%)'),
        PricingField.commissionPct => s.t('العمولة (٪)', 'Commission (%)'),
      };

  String _error(S s, PricingError e) => switch (e) {
        PricingError.required => s.t('مطلوب', 'Required'),
        PricingError.wholeNumber => s.t('رقم صحيح غير سالب', 'A whole, non-negative number'),
        PricingError.notANumber => s.t('أدخل رقماً', 'Enter a number'),
        PricingError.minAboveMax => s.t('يجب ألا تتجاوز أعلى أجرة', 'Must not exceed the maximum fare'),
        PricingError.belowRange => s.t('من ٠ إلى أقل من ١٠٠', 'From 0 to less than 100'),
        PricingError.aboveRange => s.t('من ٠ إلى ٥٠٠', 'From 0 to 500'),
        PricingError.commissionRange => s.t('من ٠ إلى ٥٠', 'From 0 to 50'),
        PricingError.commissionPrecision => s.t('منزلتان عشريتان كحد أقصى', 'At most two decimal places'),
      };

  Future<void> _save() async {
    final s = context.s;
    final r = validatePricing({for (final e in _c.entries) e.key: e.value.text}, enabled: _enabled);
    setState(() {
      _errors = r.errors;
      _reasonMissing = _reason.text.trim().isEmpty;
    });
    if (r.value == null || _reasonMissing) return;
    final next = r.value!;
    final before = widget.current;
    String line(String k, Object? a, Object b) => '$k: ${a ?? '—'} → $b';
    final changes = [
      line(s.t('أساسية', 'Base'), before?.baseFare, next.baseFare),
      line(s.t('كم', 'Km'), before?.perKm, next.perKm),
      line(s.t('دقيقة', 'Minute'), before?.perMinute, next.perMinute),
      line(s.t('أدنى', 'Min'), before?.minFare, next.minFare),
      line(s.t('أعلى', 'Max'), before?.maxFare, next.maxFare),
      line(s.t('تحت المرجعي ٪', 'Below %'), before == null ? null : pctText(before.belowReferencePct), pctText(next.belowReferencePct)),
      line(s.t('فوق المرجعي ٪', 'Above %'), before == null ? null : pctText(before.aboveReferencePct), pctText(next.aboveReferencePct)),
      line(s.t('العمولة ٪', 'Commission %'), before == null ? null : bpsText(before.commissionBps), bpsText(next.commissionBps)),
      line(s.t('مفعّلة', 'Enabled'), before?.enabled, next.enabled),
    ].join('\n');
    final ok = await confirmAction(
      context,
      title: s.t('حفظ التسعير؟', 'Save pricing?'),
      body: '${widget.zoneId} · ${s.category(widget.category)}\n\n${ltr(changes)}\n\n${s.t('يسري على الطلبات الجديدة فوراً.', 'Applies to new requests immediately.')}',
      confirmLabel: s.t('حفظ', 'Save'),
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      final v = await context.services.pricing.update(zoneId: widget.zoneId, category: widget.category, config: next, reason: _reason.text.trim(), key: IntentKey.generate());
      if (!mounted) return;
      _reason.clear();
      _loadedVersion = v;
      showSuccess(context, s.t('حُفظ — الإصدار ${ltr('$v')}', 'Saved — version ${ltr('$v')}'));
    } catch (e) {
      if (mounted) showOpsFailure(context, e, myUid: context.myUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cur = widget.current;
    final changedElsewhere = cur != null && _loadedVersion != null && cur.version != _loadedVersion;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (cur == null)
        WBanner(tone: Tone.warning, text: s.t('لا يوجد تسعير لهذه الفئة في هذه المنطقة. الحفظ ينشئه.', 'No pricing exists for this category in this zone. Saving creates it.'))
      else
        Text(s.t('الإصدار ${ltr('${cur.version}')}', 'Version ${ltr('${cur.version}')}') +
            (cur.updatedAt == null ? '' : ' · ${dateTime(cur.updatedAt!)}') +
            (cur.updatedBy == null ? '' : ' · ${ltr(shortId(cur.updatedBy!))}')),
      if (changedElsewhere)
        WBanner(
          tone: Tone.warning,
          text: s.t('تغيّر التسعير (الإصدار ${ltr('${cur.version}')}) أثناء تعديلك.', 'Pricing changed (version ${ltr('${cur.version}')}) while you were editing.'),
          actionLabel: s.t('تحميل الأحدث', 'Load latest'),
          onAction: () => setState(() => _load(cur)),
        ),
      const SizedBox(height: WSpace.md),
      for (final f in PricingField.values) ...[
        TextField(
          key: Key('pricing-${f.name}'),
          controller: _c[f],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(labelText: _label(s, f), errorText: _errors[f] == null ? null : _error(s, _errors[f]!)),
        ),
        const SizedBox(height: WSpace.md),
      ],
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _enabled,
        onChanged: (v) => setState(() => _enabled = v),
        title: Text(s.t('الفئة مفعّلة في هذه المنطقة', 'Category enabled in this zone')),
      ),
      const SizedBox(height: WSpace.sm),
      TextField(
        key: const Key('pricing-reason'),
        controller: _reason,
        maxLength: 300,
        decoration: InputDecoration(
          labelText: s.t('سبب التغيير (يُسجَّل في التدقيق)', 'Reason for the change (audited)'),
          errorText: _reasonMissing ? s.t('السبب مطلوب', 'A reason is required') : null,
        ),
      ),
      const SizedBox(height: WSpace.md),
      PrimaryAction(label: s.t('مراجعة وحفظ', 'Review and save'), icon: Icons.save_outlined, onPressed: _save),
    ]);
  }
}
