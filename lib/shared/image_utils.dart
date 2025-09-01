import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;

class ImageUtils {
  /// Converts an image file to a compressed base64 data URL
  /// Uses image compression and resizing for optimal storage
  static Future<String?> convertImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('Failed to process selected image');
      }
      
      // Resize image to max 800px width for storage optimization
      final resized = img.copyResize(decoded, width: 800);
      final jpg = img.encodeJpg(resized, quality: 70);
      final b64 = base64Encode(jpg);
      
      return 'data:image/jpeg;base64,$b64';
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  /// Converts an image file to base64 without compression (for compatibility)
  static Future<String?> convertImageToBase64Simple(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }
}
