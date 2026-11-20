import 'dart:typed_data';

import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';

/// Storage rules: uploads must be smaller than 10 MB.
const maxUploadBytes = 10 * 1024 * 1024;

/// Where a KYC file goes in Storage: drivers/{uid}/{type}/{millis}.jpg.
String storagePathFor(String uid, DocumentType type, DateTime at) => 'drivers/$uid/${type.name}/${at.millisecondsSinceEpoch}.jpg';

abstract class DocumentRepository {
  /// drivers/{uid}/documents/* keyed by type (missing = not submitted).
  Stream<Live<Map<DocumentType, ReviewDocument>>> watchDriverDocuments(String uid);

  /// vehicles/{vehicleId}/documents/* keyed by type.
  Stream<Live<Map<DocumentType, ReviewDocument>>> watchVehicleDocuments(String vehicleId);

  /// Every vehicle document of this driver (for the notifications list).
  Stream<List<ReviewDocument>> watchAllVehicleDocuments(String uid);

  /// Uploads JPEG bytes to [storagePath]; reports progress 0..1.
  Future<void> upload({required String storagePath, required Uint8List bytes, required void Function(double) onProgress});

  /// Registers the uploaded file for review. Never grants permission to work.
  Future<void> submit({required DocumentType type, required String storagePath, String? vehicleId, required IntentKey key});
}

enum PickSource { camera, gallery }

class PickedImage {
  const PickedImage(this.bytes);
  final Uint8List bytes;
}

abstract class ImagePickerPort {
  /// Returns null when the driver backs out of the picker.
  Future<PickedImage?> pick(PickSource source);
}
