import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';

/// After the first sign-in: the driver's name → registerDriver.
class NameScreen extends StatefulWidget {
  const NameScreen({super.key});
  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _name = TextEditingController();
  String? _invalid;
  IntentKey? _key;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = context.s;
    final n = _name.text.trim();
    if (n.length < 2 || n.length > 60) {
      setState(() => _invalid = s.t('اكتب اسمك الكامل (من حرفين إلى 60 حرفاً).', 'Enter your full name (2 to 60 characters).'));
      return;
    }
    setState(() => _invalid = null);
    _key ??= IntentKey.generate();
    await context.services.driver.register(name: n, key: _key!);
    // The drivers/{uid} snapshot moves the app on; nothing to do here.
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('حساب السائق', 'Driver account')),
        actions: [TextButton(onPressed: () => context.services.auth.signOut(), child: Text(s.t('خروج', 'Sign out')))],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WSpace.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(s.t('ما اسمك؟', 'What’s your name?'), style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: WSpace.sm),
            Text(s.t('يظهر اسمك للركاب عند قبول عرضك.', 'Riders see your name when they accept your offer.')),
            const SizedBox(height: WSpace.xl),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              maxLength: 60,
              onChanged: (_) => _key = null,
              decoration: InputDecoration(labelText: s.t('الاسم الكامل', 'Full name'), errorText: _invalid),
            ),
            const SizedBox(height: WSpace.lg),
            PrimaryAction(label: s.t('متابعة', 'Continue'), onPressed: _submit),
          ]),
        ),
      ),
    );
  }
}
