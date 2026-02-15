import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart'; 
import 'package:matrix/matrix.dart';

import 'package:fluffychat/utils/trust_ring_service.dart';

class TrustRingPage extends StatefulWidget {
  final Client client;
  const TrustRingPage({Key? key, required this.client}) : super(key: key);

  @override
  State<TrustRingPage> createState() => _TrustRingPageState();
}

class _TrustRingPageState extends State<TrustRingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  
  // Issue State
  Uint8List? _selectedImageBytes;
  Uint8List? _encodedImageBytes;
  bool _isEncoding = false;
  String? _selectedRoomId;

  // Redeem State
  Uint8List? _redeemImageBytes;
  Map<String, dynamic>? _decodedPayload;
  bool _isDecoding = false;
  String? _redeemError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImageForIssue() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _encodedImageBytes = null; // Reset previous encode
      });
    }
  }

  Future<void> _generateInvite() async {
    if (_selectedImageBytes == null || _selectedRoomId == null) return;

    setState(() => _isEncoding = true);

    try {
      final service = TrustRingService(widget.client);
      final encoded = await service.generateInviteImage(
        imageBytes: _selectedImageBytes!,
        roomId: _selectedRoomId!,
      );

      setState(() {
        _encodedImageBytes = encoded;
        _isEncoding = false;
      });
    } catch (e) {
      setState(() => _isEncoding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating invite: $e')),
      );
    }
  }

  Future<void> _shareInvite() async {
    if (_encodedImageBytes == null) return;
    
    // Save to file and share
    final name = 'sigma_invite_${DateTime.now().millisecondsSinceEpoch}.png';
    await Share.shareXFiles(
      [
        XFile.fromData(
          _encodedImageBytes!, 
          name: name,
          mimeType: 'image/png'
        )
      ],
      text: 'Here is your Sigma Ring of Trust invite. Share this as a FILE (not image) to preserve the key.',
    );
  }

  Future<void> _pickImageForRedeem() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _redeemImageBytes = bytes;
        _decodedPayload = null;
        _redeemError = null;
        _isDecoding = true;
      });

      try {
        final service = TrustRingService(widget.client);
        final payload = await service.redeemInvite(bytes);

        setState(() {
          _isDecoding = false;
          if (payload != null) {
            _decodedPayload = payload;
          } else {
            _redeemError = 'No valid invite found in this image.';
          }
        });
      } catch (e) {
        setState(() {
            _isDecoding = false;
            _redeemError = 'Error decoding: $e';
        });
      }
    }
  }

  Future<void> _joinRoom() async {
    if (_decodedPayload == null) return;
    final roomId = _decodedPayload!['room_id'];
    
    try {
      await widget.client.joinRoom(roomId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined room successfully!')),
      );
      Navigator.pop(context); // Go back
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join room: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ring of Trust'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Issue Invite'),
            Tab(text: 'Redeem Invite'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIssueTab(),
          _buildRedeemTab(),
        ],
      ),
    );
  }

  Widget _buildIssueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Hide an invite key inside a standard image.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          
          DropdownButtonFormField<String>(
            value: _selectedRoomId,
            hint: const Text("Select Room to Invite"),
            items: widget.client.rooms.map((room) {
              return DropdownMenuItem(
                value: room.id,
                child: Text(room.getLocalizedDisplayname()),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedRoomId = val),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _pickImageForIssue,
            icon: const Icon(Icons.image),
            label: const Text('Select Cover Image'),
          ),
          
          if (_selectedImageBytes != null) ...[
            const SizedBox(height: 20),
            Image.memory(_selectedImageBytes!, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 20),
            
            if (_isEncoding)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _selectedRoomId != null ? _generateInvite : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text('Generate Invite Image'),
              ),
          ],

          if (_encodedImageBytes != null) ...[
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              'Invite Generated!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Use the button below to share. \nIMPORTANT: Send as a FILE request if using WhatsApp/Discord to prevent compression.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _shareInvite,
              icon: const Icon(Icons.share),
              label: const Text('Share Invite File'),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildRedeemTab() {
     return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Received a strange image? Scan it here to check for hidden invites.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 30),
          
          ElevatedButton.icon(
            onPressed: _pickImageForRedeem,
            icon: const Icon(Icons.qr_code_scanner), // Icon metaphor
            label: const Text('Scan Image for Invite'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
          ),

          if (_isDecoding)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (_redeemError != null)
             Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _redeemError!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

          if (_decodedPayload != null) ...[
            const SizedBox(height: 30),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 50),
                    const SizedBox(height: 10),
                    const Text(
                      'Valid Invite Found!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Room ID'),
                      subtitle: Text(_decodedPayload!['room_id'] ?? 'Unknown'),
                    ),
                    ListTile(
                      title: const Text('Invited By'),
                      subtitle: Text(_decodedPayload!['inviter'] ?? 'Unknown'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _joinRoom, 
                      child: const Text('Join Room Now')
                    )
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
