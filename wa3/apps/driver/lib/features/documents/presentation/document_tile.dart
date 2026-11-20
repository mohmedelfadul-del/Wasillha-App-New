import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';
import '../application/upload_controller.dart';
import '../domain/document_repository.dart';

/// One KYC document: the server's decision (with the reason and what to fix)
/// plus the local upload flow with progress and retry.
class DocumentTile extends StatefulWidget {
  const DocumentTile({super.key, required this.uid, required this.type, required this.doc, this.vehicleId});
  final String uid;
  final DocumentType type;
  final ReviewDocument? doc;
  final String? vehicleId;
  @override
  State<DocumentTile> createState() => _DocumentTileState();
}

class _DocumentTileState extends State<DocumentTile> {
  late final UploadController _c = UploadController(
    repo: context.services.documents,
    uid: widget.uid,
    type: widget.type,
    vehicleId: widget.vehicleId,
    clock: context.services.clock,
  );

  @override
  void didUpdateWidget(DocumentTile old) {
    super.didUpdateWidget(old);
    // A new server snapshot of this document supersedes the local flow.
    if (_c.phase == UploadPhase.submitted && old.doc?.submittedAt != widget.doc?.submittedAt) _c.reset();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final s = context.s;
    final source = await showModalBottomSheet<PickSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_camera_outlined), title: Text(s.t('التقط صورة', 'Take a photo')), onTap: () => Navigator.pop(ctx, PickSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: Text(s.t('اختر من المعرض', 'Choose from gallery')), onTap: () => Navigator.pop(ctx, PickSource.gallery)),
        ]),
      ),
    );
    if (source == null || !mounted) return;
    PickedImage? img;
    try {
      img = await context.services.picker.pick(source);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.t('لا يمكن فتح الكاميرا أو المعرض. اسمح بالوصول من إعدادات الهاتف.', 'We can’t open the camera or gallery. Allow access in your phone’s settings.')),
        ));
      }
      return;
    }
    if (img != null) await _c.start(img.bytes);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final doc = widget.doc;
        final status = doc?.status;
        final needsFix = status == ReviewStatus.rejected || status == ReviewStatus.changesRequested;
        final canUpload = !_c.busy && _c.phase != UploadPhase.submitted && (doc == null || needsFix);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(WSpace.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.docType(widget.type), style: t.titleMedium),
              const SizedBox(height: WSpace.sm),
              _badge(s, doc),
              if (needsFix && _c.phase == UploadPhase.idle) ...[
                const SizedBox(height: WSpace.sm),
                Text('${s.t('السبب', 'Reason')}: ${(doc!.reason ?? '').trim().isEmpty ? s.t('لم يُذكر سبب — تواصل مع الدعم.', 'No reason given — contact support.') : doc.reason}'),
                const SizedBox(height: WSpace.xs),
                Text(
                  status == ReviewStatus.rejected
                      ? s.t('ما المطلوب: ارفع صورة جديدة تعالج هذا السبب. يجب أن تكون الوثيقة كاملة وواضحة وسارية.', 'What to fix: upload a new photo that addresses this reason. The whole document must be visible, sharp and valid.')
                      : s.t('ما المطلوب: عدّل ما ذُكر أعلاه ثم ارفع صورة جديدة.', 'What to fix: correct what is described above, then upload a new photo.'),
                  style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
              if (status == ReviewStatus.pending && doc != null && _c.phase == UploadPhase.idle) ...[
                const SizedBox(height: WSpace.sm),
                Text(s.t('أُرسلت للمراجعة. سنعرض القرار هنا.', 'Sent for review. The decision will appear here.')),
              ],
              ..._localState(s),
              if (canUpload) ...[
                const SizedBox(height: WSpace.md),
                OutlinedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.upload_file),
                  label: Text(doc == null && _c.phase == UploadPhase.idle ? s.t('ارفع الوثيقة', 'Upload') : s.t('ارفع صورة جديدة', 'Upload again')),
                ),
              ],
            ]),
          ),
        );
      },
    );
  }

  Widget _badge(S s, ReviewDocument? doc) => switch (doc?.status) {
        null => StatusBadge(tone: Tone.neutral, label: s.t('لم تُرفع بعد', 'Not uploaded')),
        ReviewStatus.pending => StatusBadge(tone: Tone.info, label: s.review(ReviewStatus.pending)),
        ReviewStatus.approved => StatusBadge(tone: Tone.success, label: s.review(ReviewStatus.approved)),
        ReviewStatus.rejected => StatusBadge(tone: Tone.error, label: s.review(ReviewStatus.rejected)),
        ReviewStatus.changesRequested => StatusBadge(tone: Tone.warning, label: s.review(ReviewStatus.changesRequested)),
      };

  List<Widget> _localState(S s) => switch (_c.phase) {
        UploadPhase.idle => const [],
        UploadPhase.uploading => [
            const SizedBox(height: WSpace.md),
            Text('${s.t('جارٍ الرفع', 'Uploading')} ${ltr('${(_c.progress * 100).round()}%')}'),
            const SizedBox(height: WSpace.xs),
            LinearProgressIndicator(value: _c.progress),
          ],
        UploadPhase.submitting => [const SizedBox(height: WSpace.md), Text(s.t('جارٍ الإرسال للمراجعة…', 'Sending for review…')), const LinearProgressIndicator()],
        UploadPhase.submitted => [
            const SizedBox(height: WSpace.md),
            WBanner(tone: Tone.success, text: s.t('استلمنا الوثيقة. هي الآن قيد المراجعة.', 'We received the document. It is now under review.')),
          ],
        UploadPhase.failed => [
            const SizedBox(height: WSpace.md),
            WBanner(
              tone: Tone.error,
              text: _c.tooLarge
                  ? s.t('الصورة أكبر من 10 ميغابايت. اختر صورة أصغر.', 'This photo is larger than 10 MB. Choose a smaller one.')
                  : '${s.t('لم يكتمل الرفع.', 'The upload didn’t finish.')} ${s.error(_c.error?.code ?? 'network', _c.error?.message)}',
            ),
            if (!_c.tooLarge) ...[
              const SizedBox(height: WSpace.sm),
              FilledButton.icon(onPressed: _c.retry, icon: const Icon(Icons.refresh), label: Text(s.retry)),
            ],
          ],
      };
}
