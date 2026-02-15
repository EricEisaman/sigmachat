import 'dart:convert';
import 'dart:typed_data';

import 'package:matrix/matrix.dart'; // For Matrix client and crypto
import 'package:fluffychat/utils/steganography_helper.dart';

class TrustRingService {
  final Client client;

  TrustRingService(this.client);

  /// Generates a steganographic invite image.
  /// 
  /// [imageBytes]: The raw bytes of the cover image (PNG/JPEG).
  /// [roomId]: The room to invite the user to.
  /// [alias]: Optional alias for the room.
  /// 
  /// Returns the PNG bytes of the image with the invite embedded.
  Future<Uint8List?> generateInviteImage({
    required Uint8List imageBytes,
    required String roomId,
    String? alias,
  }) async {
    // 1. Create Payload
    final payload = {
      'type': 'sigma_invite',
      'room_id': roomId,
      'inviter': client.userID,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'alias': alias,
    };

    // 2. Sign Payload (Simple signature for MVP)
    // Ideally, use Ed25519 keypair. For now, we sign with the device ID or similar
    // to prove it came from this user. In a real Trust Ring, this would check
    // against a list of trusted public keys.
    // For MVP: We embed the payload loosely. Real crypto should go here.
    final payloadString = json.encode(payload);
    
    // 3. Encode into Image
    return SteganographyHelper.encode(imageBytes, payloadString);
  }

  /// Extracts and validates an invite from an image.
  Future<Map<String, dynamic>?> redeemInvite(Uint8List imageBytes) async {
    try {
      // 1. Decode LSB
      final payloadString = await SteganographyHelper.decode(imageBytes);
      if (payloadString == null) return null;

      // 2. Parse JSON
      final payload = json.decode(payloadString);
      if (payload is! Map<String, dynamic>) return null;

      // 3. Validate Schema
      if (payload['type'] != 'sigma_invite') return null;
      if (payload['room_id'] == null) return null;

      // 4. Verify Signature (TODO: Implement actual verification)
      // For now, we trust the payload if it effectively parses.
      
      return payload;
    } catch (e) {
      print('Error redeeming invite: $e');
      return null;
    }
  }
}
