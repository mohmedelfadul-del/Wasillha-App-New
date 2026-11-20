import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// Full-screen, bilingual configuration error. There is no fake mode.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, this.missing = const [], this.error});

  /// Missing `--dart-define` names.
  final List<String> missing;

  /// Firebase initialization error, when the defines were present.
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wasilha Ops',
      theme: wasilhaTheme(Brightness.light),
      darkTheme: wasilhaTheme(Brightness.dark),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(WSpace.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.settings_suggest_outlined, size: 40, color: WColors.error, semanticLabel: 'Configuration error'),
                  const SizedBox(height: WSpace.md),
                  Text('لوحة التشغيل غير مُعدّة', style: Theme.of(context).textTheme.headlineMedium, textDirection: TextDirection.rtl),
                  Text('The operations console is not configured', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: WSpace.lg),
                  if (missing.isNotEmpty) ...[
                    const Text('Missing build settings (pass each with --dart-define=NAME=value):'),
                    const SizedBox(height: WSpace.sm),
                    for (final m in missing)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: SelectableText('• $m', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                      ),
                  ],
                  if (error != null) ...[
                    const Text('Firebase failed to initialize with the provided options:'),
                    const SizedBox(height: WSpace.sm),
                    SelectableText('$error', style: const TextStyle(fontFamily: 'monospace')),
                  ],
                  const SizedBox(height: WSpace.lg),
                  const Text('Example: flutter run -d chrome --dart-define=FIREBASE_API_KEY=… --dart-define=FIREBASE_PROJECT_ID=…'),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
