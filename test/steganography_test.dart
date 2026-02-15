import 'dart:convert';
import 'dart:typed_data';

import 'package:fluffychat/utils/steganography_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('SteganographyHelper encodes and decodes correctly', () async {
    // 1. Create a dummy image (10x10)
    final image = img.Image(width: 10, height: 10);
    // Fill with random noise? Or just leave black.
    
    final pngBytes = Uint8List.fromList(img.encodePng(image));

    // 2. Define message
    const message = "Secret Key 12345";

    // 3. Encode
    final encodedBytes = await SteganographyHelper.encode(pngBytes, message);
    expect(encodedBytes, isNotNull);
    
    // 4. Decode
    final decodedMessage = await SteganographyHelper.decode(encodedBytes!);
    
    // 5. Assert
    expect(decodedMessage, equals(message));
  });

   test('SteganographyHelper throws on huge message', () async {
    // 1x1 pixel image = 3 bytes capacity
    final image = img.Image(width: 1, height: 1);
    final pngBytes = Uint8List.fromList(img.encodePng(image));

    // Message length header (4 bytes) + 1 byte char > 3 bytes
    const message = "A"; 

    expect(
      () async => await SteganographyHelper.encode(pngBytes, message),
      throwsException
    );
  });
}
