import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../common/presentation/digits.dart';
import '../application/phone_sign_in_controller.dart';
import 'auth_messages.dart';

/// SMS code entry with resend timer and auto-verification state.
class CodeStep extends StatefulWidget {
  const CodeStep({super.key, required this.controller});
  final PhoneSignInController controller;
  @override
  State<CodeStep> createState() => _CodeStepState();
}

class _CodeStepState extends State<CodeStep> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final s = context.s;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(WSpace.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(s.t('أدخل الرمز', 'Enter the code'), style: theme.textTheme.headlineMedium),
        const SizedBox(height: WSpace.sm),
        Text('${s.t('أرسلنا رمزاً من 6 أرقام إلى', 'We sent a 6-digit code to')} ${ltr(c.e164 ?? '')}', style: theme.textTheme.bodyMedium),
        const SizedBox(height: WSpace.xl),
        if (c.autoVerifying) ...[
          Row(children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: WSpace.md),
            Expanded(child: Text(s.t('جارٍ التحقق تلقائياً…', 'Verifying automatically…'))),
          ]),
          const SizedBox(height: WSpace.lg),
        ],
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 8),
            inputFormatters: [const AsciiDigitsFormatter(), LengthLimitingTextInputFormatter(6)],
            decoration: InputDecoration(
              labelText: s.t('رمز التحقق', 'Verification code'),
              errorText: c.error == null ? null : authMessage(s, c.error!),
              errorMaxLines: 4,
            ),
            onChanged: (v) {
              c.clearError();
              setState(() {});
            },
            onSubmitted: (v) => c.verify(v),
          ),
        ),
        const SizedBox(height: WSpace.xl),
        PrimaryAction(
          label: s.t('تحقّق', 'Verify'),
          onPressed: _code.text.length == 6 && !c.autoVerifying ? () => c.verify(_code.text) : null,
        ),
        const SizedBox(height: WSpace.md),
        if (c.resendAvailableAt != null)
          Countdown(
            key: ValueKey(c.resendAvailableAt),
            until: c.resendAvailableAt!,
            onDone: () => setState(() {}),
            builder: (context, left) => left > Duration.zero
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: WSpace.md),
                    child: Text('${s.t('يمكنك طلب رمز جديد بعد', 'You can ask for a new code in')} ${mmss(left)}',
                        textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  )
                : TextButton(
                    onPressed: () {
                      _code.clear();
                      c.resend(lang: s.lang);
                    },
                    child: Text(s.t('أرسل رمزاً جديداً', 'Send a new code')),
                  ),
          ),
        TextButton(onPressed: c.changeNumber, child: Text(s.t('تغيير الرقم', 'Change number'))),
      ]),
    );
  }
}
