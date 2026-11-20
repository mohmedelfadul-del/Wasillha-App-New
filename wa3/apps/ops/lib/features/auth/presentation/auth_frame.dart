import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/widgets/settings_actions.dart';

/// Shared layout for the sign-in steps.
class AuthFrame extends StatelessWidget {
  const AuthFrame({super.key, required this.title, required this.children, this.error});
  final String title;
  final List<Widget> children;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.s.t('وصلها · التشغيل', 'Wasilha · Operations')), actions: const [SettingsActions()]),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(WSpace.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
                  const SizedBox(height: WSpace.lg),
                  if (error != null) ...[WBanner(tone: Tone.error, text: error!), const SizedBox(height: WSpace.md)],
                  ...children,
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CodeField extends StatelessWidget {
  const CodeField({super.key, required this.controller, required this.onSubmitted});
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  @override
  Widget build(BuildContext context) => TextField(
        key: const Key('totp-code'),
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        maxLength: 6,
        autofillHints: const [AutofillHints.oneTimeCode],
        onSubmitted: (_) => onSubmitted(),
        decoration: InputDecoration(labelText: context.s.t('رمز تطبيق المصادقة (٦ أرقام)', 'Authenticator code (6 digits)')),
      );
}
