import 'package:flutter/foundation.dart';
import 'package:wa3_core/wa3_core.dart';

import '../domain/document_repository.dart';

enum UploadPhase { idle, uploading, submitting, failed, submitted }

/// One document's upload → submit flow. Keeps the picked bytes so a failure
/// can be retried without picking again; a retry after a successful upload
/// only re-submits (same idempotency key).
class UploadController extends ChangeNotifier {
  UploadController({required this.repo, required this.uid, required this.type, this.vehicleId, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;
  final DocumentRepository repo;
  final String uid;
  final DocumentType type;
  final String? vehicleId;
  final DateTime Function() _clock;

  UploadPhase phase = UploadPhase.idle;
  double progress = 0;
  ApiFailure? error;

  /// Client-side validation failure (file too large).
  bool tooLarge = false;

  Uint8List? _bytes;
  String? _uploadedPath;
  IntentKey? _key;

  bool get busy => phase == UploadPhase.uploading || phase == UploadPhase.submitting;

  /// Starts a new intent with freshly picked bytes.
  Future<void> start(Uint8List bytes) async {
    tooLarge = bytes.lengthInBytes >= maxUploadBytes;
    if (tooLarge) {
      phase = UploadPhase.failed;
      error = null;
      notifyListeners();
      return;
    }
    _bytes = bytes;
    _uploadedPath = null;
    _key = IntentKey.generate();
    await _run();
  }

  Future<void> retry() async {
    if (_bytes == null || busy) return;
    await _run();
  }

  Future<void> _run() async {
    error = null;
    try {
      if (_uploadedPath == null) {
        phase = UploadPhase.uploading;
        progress = 0;
        notifyListeners();
        // A fresh path each attempt: Storage rules forbid overwriting a file.
        final path = storagePathFor(uid, type, _clock());
        await repo.upload(storagePath: path, bytes: _bytes!, onProgress: (p) {
          progress = p;
          notifyListeners();
        });
        _uploadedPath = path;
      }
      phase = UploadPhase.submitting;
      notifyListeners();
      await repo.submit(type: type, storagePath: _uploadedPath!, vehicleId: vehicleId, key: _key!);
      phase = UploadPhase.submitted;
      _bytes = null;
    } on ApiFailure catch (e) {
      error = e;
      phase = UploadPhase.failed;
    } catch (e) {
      error = ApiFailure('network', e.toString());
      phase = UploadPhase.failed;
    }
    notifyListeners();
  }

  /// The server's document snapshot superseded the local flow.
  void reset() {
    phase = UploadPhase.idle;
    progress = 0;
    error = null;
    tooLarge = false;
    notifyListeners();
  }
}
