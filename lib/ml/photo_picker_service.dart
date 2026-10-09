// PhotoPickerService — wraps image_picker for the photo fallback flow.

import 'package:image_picker/image_picker.dart';

// ---------------------------------------------------------------------------
// PhotoPickerService
// ---------------------------------------------------------------------------

class PhotoPickerService {
  final ImagePicker _picker = ImagePicker();

  /// Opens the gallery. Returns the picked image file path, or null if the
  /// user cancelled.
  Future<String?> pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    return file?.path;
  }
}
