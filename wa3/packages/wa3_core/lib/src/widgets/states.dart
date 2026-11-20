import 'package:flutter/material.dart';

import '../data/api.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';

/// One component for every non-content state: loading, empty, error with
/// retry, offline, permission denied. Screens never improvise these.
class WStateView extends StatelessWidget {
  const WStateView._({required this.icon, required this.title, this.body, this.actionLabel, this.onAction, this.loading = false, this.tone});

  factory WStateView.loading({String? label}) => WStateView._(icon: Icons.hourglass_empty, title: label ?? '', loading: true);

  factory WStateView.empty({required IconData icon, required String title, String? body, String? actionLabel, VoidCallback? onAction}) =>
      WStateView._(icon: icon, title: title, body: body, actionLabel: actionLabel, onAction: onAction);

  /// Error with retry. Uses the failure's code for a precise message.
  static Widget error(BuildContext context, Object error, {VoidCallback? onRetry}) {
    final s = context.s;
    final f = error is ApiFailure ? error : null;
    if (f?.isNetwork ?? false) return WStateView.offline(context, onRetry: onRetry);
    if (f?.code == 'permission_denied') return WStateView.permissionDenied(context);
    return WStateView._(
      icon: Icons.error_outline,
      title: s.somethingWrong,
      body: f == null ? s.error('internal') : s.error(f.code, f.message),
      actionLabel: onRetry == null ? null : s.retry,
      onAction: onRetry,
      tone: WColors.error,
    );
  }

  static Widget offline(BuildContext context, {VoidCallback? onRetry}) {
    final s = context.s;
    return WStateView._(icon: Icons.wifi_off, title: s.offlineTitle, body: s.offlineBody, actionLabel: onRetry == null ? null : s.retry, onAction: onRetry);
  }

  static Widget permissionDenied(BuildContext context, {String? body}) =>
      WStateView._(icon: Icons.lock_outline, title: context.s.permissionDenied, body: body);

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(WSpace.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (loading)
              Semantics(label: title.isEmpty ? context.s.loading : title, child: const CircularProgressIndicator())
            else
              Icon(icon, size: 40, color: tone ?? theme.colorScheme.onSurfaceVariant, semanticLabel: title),
            if (title.isNotEmpty) ...[
              const SizedBox(height: WSpace.md),
              Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            ],
            if (body != null) ...[
              const SizedBox(height: WSpace.sm),
              Text(body!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: WSpace.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ]),
        ),
      ),
    );
  }
}

enum Tone { success, warning, error, info, neutral }

/// Color is never the only signal: every badge pairs color with an icon and text.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.tone, required this.label});
  final Tone tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (fg, bg, icon) = switch (tone) {
      Tone.success => (WColors.success, WColors.successBg, Icons.check_circle),
      Tone.warning => (WColors.warning, WColors.warningBg, Icons.warning_amber_rounded),
      Tone.error => (WColors.error, WColors.errorBg, Icons.error),
      Tone.info => (cs.primary, cs.primary.withValues(alpha: 0.10), Icons.info),
      Tone.neutral => (cs.onSurfaceVariant, cs.outline.withValues(alpha: 0.35), Icons.circle_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: fg),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }
}

/// Full-width banner for stale data / offline / warnings at the top of a screen.
class WBanner extends StatelessWidget {
  const WBanner({super.key, required this.tone, required this.text, this.actionLabel, this.onAction});
  final Tone tone;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, icon) = switch (tone) {
      Tone.error => (WColors.error, WColors.errorBg, Icons.error_outline),
      Tone.success => (WColors.success, WColors.successBg, Icons.check_circle_outline),
      _ => (WColors.warning, WColors.warningBg, Icons.warning_amber_rounded),
    };
    return Semantics(
      liveRegion: true,
      child: Material(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: WSpace.lg, vertical: WSpace.sm),
          child: Row(children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: WSpace.sm),
            Expanded(child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w500))),
            if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!, style: TextStyle(color: fg))),
          ]),
        ),
      ),
    );
  }
}
