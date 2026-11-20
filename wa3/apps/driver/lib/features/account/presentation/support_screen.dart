import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/config.dart';
import '../../../app/services.dart';

/// Call or WhatsApp the operations team (number configurable, see AppConfig).
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    if (!await context.services.launcher.open(uri) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.s.t('لا يوجد تطبيق لفتح هذا.', 'No app on this phone can open this.'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('الدعم', 'Support'))),
      body: ListView(padding: const EdgeInsets.all(WSpace.lg), children: [
        Text(s.t('فريق العمليات يساعدك في الوثائق والحساب والرحلات والمبالغ.', 'The operations team helps with documents, your account, trips and money.')),
        const SizedBox(height: WSpace.sm),
        Text('${s.t('الرقم', 'Number')}: ${ltr(AppConfig.opsPhone)}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: WSpace.xl),
        PrimaryAction(label: s.t('اتصل بالدعم', 'Call support'), icon: Icons.call, large: true, onPressed: () => _open(context, telUri(AppConfig.opsPhone))),
        const SizedBox(height: WSpace.md),
        OutlinedButton.icon(
          onPressed: () => _open(context, whatsAppUri(AppConfig.opsWhatsApp)),
          icon: const Icon(Icons.chat_outlined),
          label: Text(s.t('راسلنا على واتساب', 'Message us on WhatsApp')),
        ),
        const SizedBox(height: WSpace.xl),
        Text(s.t('في حالة خطر على السلامة اتصل بالشرطة أولاً.', 'If anyone’s safety is at risk, call the police first.')),
      ]),
    );
  }
}
