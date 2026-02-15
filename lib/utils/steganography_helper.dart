import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'dart:convert';

class SteganographyHelper {
  /// Encodes a string message into an image using LSB steganography.
  /// Returns the PNG encoded bytes of the modified image.
  static Future<Uint8List?> encode(Uint8List imageBytes, String message) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    final messageBytes = utf8.encode(message);
    // 4 bytes for length
    final lengthBytes = _intToBytes(messageBytes.length);
    final dataToHide = [...lengthBytes, ...messageBytes];

    // Check capacity: each pixel has 3 channels (RGB) we can use. 
    // We need 8 bits per byte of data.
    final maxBytes = (image.width * image.height * 3) ~/ 8;
    if (dataToHide.length > maxBytes) {
      throw Exception('Message too long for this image. Max bytes: $maxBytes, Need: ${dataToHide.length}');
    }

    int dataIndex = 0;
    int bitIndex = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (dataIndex >= dataToHide.length) break;

        img.Pixel pixel = image.getPixel(x, y);
        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        // Encode into Red channel
        if (dataIndex < dataToHide.length) {
          int bit = (dataToHide[dataIndex] >> bitIndex) & 1;
          r = (r & 0xFE) | bit;
          bitIndex++;
          if (bitIndex == 8) {
            bitIndex = 0;
            dataIndex++;
          }
        }

        // Encode into Green channel
        if (dataIndex < dataToHide.length) {
          int bit = (dataToHide[dataIndex] >> bitIndex) & 1;
          g = (g & 0xFE) | bit;
          bitIndex++;
          if (bitIndex == 8) {
            bitIndex = 0;
            dataIndex++;
          }
        }

        // Encode into Blue channel
        if (dataIndex < dataToHide.length) {
          int bit = (dataToHide[dataIndex] >> bitIndex) & 1;
          b = (b & 0xFE) | bit;
          bitIndex++;
          if (bitIndex == 8) {
            bitIndex = 0;
            dataIndex++;
          }
        }

        image.setPixelRgb(x, y, r, g, b);
      }
      if (dataIndex >= dataToHide.length) break;
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  /// Decodes a hidden string message from an image.
  static Future<String?> decode(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    List<int> extractedBytes = [];
    int currentByte = 0;
    int bitIndex = 0;
    int? messageLength;
    
    // Iterate pixels
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        img.Pixel pixel = image.getPixel(x, y);
        List<int> channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];

        for (int c in channels) {
          int bit = c & 1;
          
          if (bit == 1) {
             currentByte |= (1 << bitIndex);
          }
          bitIndex++;

          if (bitIndex == 8) {
            extractedBytes.add(currentByte);
            currentByte = 0;
            bitIndex = 0;

            // Check if we have the length header (4 bytes)
            if (messageLength == null && extractedBytes.length == 4) {
              messageLength = _bytesToInt(extractedBytes);
              extractedBytes.clear();
            } 
            // Check if we have the full message
            else if (messageLength != null && extractedBytes.length == messageLength) {
              return utf8.decode(extractedBytes);
            }
          }
        }
        if (messageLength != null && extractedBytes.length == messageLength) break;
      }
      if (messageLength != null && extractedBytes.length == messageLength) break;
    }

    return null;
  }

  static List<int> _intToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  static int _bytesToInt(List<int> bytes) {
    return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
  }
}
