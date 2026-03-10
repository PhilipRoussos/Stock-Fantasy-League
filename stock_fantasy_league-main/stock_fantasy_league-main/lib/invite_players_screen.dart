import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:qr_flutter/qr_flutter.dart';

class InvitePlayersScreen extends StatefulWidget {
  final String leagueCode;
  
  const InvitePlayersScreen({super.key, required this.leagueCode});

  @override
  State<InvitePlayersScreen> createState() => _InvitePlayersScreenState();
}

class _InvitePlayersScreenState extends State<InvitePlayersScreen> {
  final Strategy strategy = Strategy.P2P_POINT_TO_POINT;
  bool isAdvertising = false;

  @override
  void dispose() {
    Nearby().stopAdvertising();
    super.dispose();
  }

  Future<void> _startBluetoothShare() async {
    if (isAdvertising) {
      await Nearby().stopAdvertising();
      setState(() { isAdvertising = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stopped Sharing")));
      return;
    }

    if (!await _checkPermissions()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Permissions missing for Bluetooth Share")));
      return;
    }

    try {
      bool success = await Nearby().startAdvertising(
        "League Host", 
        strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) {
           Nearby().acceptConnection(
             id, 
             onPayLoadRecieved: (endId, payload) {/* Host doesn't read payloads */}
           );
           
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connecting to ${info.endpointName}...")));
        },
        onConnectionResult: (String id, Status status) {
           if (status == Status.CONNECTED) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connected! Sending Code...")));
             Nearby().sendBytesPayload(id, Uint8List.fromList(utf8.encode(widget.leagueCode)));
           } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Failed")));
           }
        },
        onDisconnected: (String id) {},
      );
      
      setState(() { isAdvertising = success; });
      if (success) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Looking for nearby devices...")));
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<bool> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan, 
      Permission.nearbyWifiDevices
    ].request();
    
    return !statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied);
  }

  void _showQrCodeDialog() {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text("Scan to Join"),
        content: SizedBox(
          width: 250, 
          height: 250,
          child: Center(
            child: QrImageView(
              data: widget.leagueCode,
              version: QrVersions.auto,
              size: 250.0,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Invite Players"),
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            const Text(
              "Share Code", 
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF2A0D55)
              )
            ),
            const SizedBox(height: 16),
          
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.leagueCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Code copied to clipboard!")),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.content_copy, color: Colors.black, size: 28),
                  const SizedBox(width: 12),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A0D55),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "#${widget.leagueCode}", 
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      )
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 50),
            
            Center(
              child: _buildCustomTileButton(
                context, 
                isAdvertising ? "Stop Sharing" : "Share via Bluetooth", 
                isAdvertising ? Icons.stop_circle_outlined : Icons.bluetooth, 
                _startBluetoothShare,
                isActive: isAdvertising
              )
            ),
            
            if (isAdvertising)
               const Padding(
                 padding: EdgeInsets.only(top: 20),
                 child: Center(child: CircularProgressIndicator()),
               ),
            
            const SizedBox(height: 20),
            Center(
              child: _buildCustomTileButton(
                context, 
                "Show QR Code", 
                Icons.qr_code, 
                _showQrCodeDialog
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTileButton(BuildContext context, String text, IconData icon, VoidCallback onPressed, {bool isActive = false}) {
    return SizedBox(
       width: 220, 
       height: 80,
       child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.redAccent : const Color(0xFF2A0D55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Icon(icon, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}