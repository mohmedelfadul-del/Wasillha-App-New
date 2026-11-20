import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';
import '../../../app/widgets/failure.dart';

/// The uploaded file: inline image preview when it is an image, and always a
/// link to open the original (PDFs open in a new tab).
class KycFilePreview extends StatefulWidget {
  const KycFilePreview({super.key, required this.storagePath});
  final String storagePath;
  @override
  State<KycFilePreview> createState() => _KycFilePreviewState();
}

class _KycFilePreviewState extends State<KycFilePreview> {
  Future<String>? _url;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _url ??= context.services.kyc.downloadUrl(widget.storagePath);
  }

  bool get _looksPdf => widget.storagePath.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return FutureBuilder<String>(
      future: _url,
      builder: (context, snap) {
        if (snap.hasError) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            WBanner(tone: Tone.error, text: describeFailure(s, snap.error is ApiFailure ? snap.error as ApiFailure : ApiFailure('internal', '${snap.error}'))),
            TextButton(onPressed: () => setState(() => _url = context.services.kyc.downloadUrl(widget.storagePath)), child: Text(s.retry)),
          ]);
        }
        if (!snap.hasData) return SizedBox(height: 120, child: WStateView.loading(label: s.t('نحمّل الملف…', 'Loading the file…')));
        final url = snap.data!;
        final open = OutlinedButton.icon(
          onPressed: () => launchUrl(Uri.parse(url), webOnlyWindowName: '_blank'),
          icon: const Icon(Icons.open_in_new),
          label: Text(s.t('فتح الملف الأصلي', 'Open the original file')),
        );
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!_looksPdf)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 520),
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  semanticLabel: s.t('صورة الوثيقة', 'Document image'),
                  loadingBuilder: (c, child, p) => p == null ? child : const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                  errorBuilder: (c, e, st) => WBanner(tone: Tone.warning, text: s.t('لا يمكن عرض المعاينة. افتح الملف الأصلي.', 'The preview can’t be shown. Open the original file.')),
                ),
              ),
            )
          else
            WBanner(tone: Tone.warning, text: s.t('الملف بصيغة PDF — افتحه للمراجعة.', 'This file is a PDF — open it to review.')),
          const SizedBox(height: WSpace.sm),
          open,
        ]);
      },
    );
  }
}
