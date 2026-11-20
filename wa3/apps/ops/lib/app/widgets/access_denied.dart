import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../features/auth/domain/auth_repository.dart';
import '../sections.dart';

/// Inline access-denied state for a section the role cannot use.
class SectionAccessDenied extends StatelessWidget {
  const SectionAccessDenied({super.key, required this.section, required this.role});
  final Section section;
  final StaffRole? role;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final needed = {StaffRole.admin, ...section.roles}.map((r) => roleLabel(s, r)).join(s.t('، ', ', '));
    return WStateView.permissionDenied(
      context,
      body: s.t('«${section.label(s)}» متاح لـ: $needed. دورك: ${role == null ? '—' : roleLabel(s, role!)}.',
          '“${section.label(s)}” is for: $needed. Your role: ${role == null ? '—' : roleLabel(s, role!)}.'),
    );
  }
}

/// Full-screen state for an account that is not authorized staff.
class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key, required this.session, required this.onSignOut});
  final StaffSession session;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final why = !session.staff
        ? s.t('هذا الحساب ليس حساب موظف في وصلها.', 'This account is not a Wasilha staff account.')
        : s.t('لم يُسنَد لهذا الحساب دور (مدير، عمليات، وثائق، دعم، مالية).', 'This account has no staff role (admin, operations, kyc, support, finance).');
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(WSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Icon(Icons.lock_outline, size: 40, color: WColors.error),
                const SizedBox(height: WSpace.md),
                Semantics(header: true, child: Text(s.t('لا يمكنك الدخول إلى لوحة التشغيل', 'You can’t use the operations console'), style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center)),
                const SizedBox(height: WSpace.sm),
                Text(why, textAlign: TextAlign.center),
                const SizedBox(height: WSpace.sm),
                Text(s.t('اطلب من مدير النظام إسناد دور لك، ثم سجّل الخروج والدخول مجدداً.', 'Ask an admin to assign you a role, then sign out and sign in again.'), textAlign: TextAlign.center),
                const SizedBox(height: WSpace.md),
                Text(ltr(session.email ?? session.uid), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: WSpace.lg),
                PrimaryAction(label: s.t('تسجيل الخروج', 'Sign out'), icon: Icons.logout, onPressed: onSignOut),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
