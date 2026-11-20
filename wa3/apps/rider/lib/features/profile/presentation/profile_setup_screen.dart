import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';

/// Minimal profile after the first sign-in → `registerRider`.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = context.s;
    final name = _name.text.trim();
    if (name.length < 2) {
      setState(() => _error = s.t('اكتب اسمك (حرفان على الأقل).', 'Enter your name (at least 2 letters).'));
      return;
    }
    setState(() => _error = null);
    await context.deps.profile.register(name: name, lang: s.lang, key: IntentKey.generate());
    // The riders/{uid} listener moves on to the home screen once the server has written it.
    if (mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(actions: [
        TextButton(onPressed: () => context.deps.auth.signOut(), child: Text(s.t('خروج', 'Sign out'))),
      ]),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WSpace.xl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(s.t('ما اسمك؟', 'What’s your name?'), style: theme.textTheme.headlineMedium),
            const SizedBox(height: WSpace.sm),
            Text(s.t('سيظهر اسمك للسائق الذي يقبل رحلتك.', 'Your name is shown to the driver who takes your trip.')),
            const SizedBox(height: WSpace.xl),
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: InputDecoration(labelText: s.t('الاسم', 'Name'), errorText: _error, errorMaxLines: 3),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: WSpace.lg),
            if (_sent) ...[
              Row(children: [
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: WSpace.md),
                Expanded(child: Text(s.t('جارٍ إنشاء حسابك…', 'Setting up your account…'))),
              ]),
              const SizedBox(height: WSpace.lg),
            ],
            PrimaryAction(label: s.t('متابعة', 'Continue'), onPressed: _submit),
          ]),
        ),
      ),
    );
  }
}
