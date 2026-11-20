import 'package:image_picker/image_picker.dart';

import '../domain/document_repository.dart';

class ImagePickerAdapter implements ImagePickerPort {
  ImagePickerAdapter([ImagePicker? picker]) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  @override
  Future<PickedImage?> pick(PickSource source) async {
    // imageQuality makes the plugin re-encode as JPEG and keeps files small.
    final f = await _picker.pickImage(
      source: source == PickSource.camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2400,
      maxHeight: 2400,
      requestFullMetadata: false,
    );
    if (f == null) return null;
    return PickedImage(await f.readAsBytes());
  }
}
