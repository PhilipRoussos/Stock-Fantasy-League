import 'package:flutter/material.dart';
import 'data_model.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'package:mobile_scanner/mobile_scanner.dart';

class JoinLeagueScreen extends StatefulWidget {
  const JoinLeagueScreen({super.key});

  @override
  State<JoinLeagueScreen> createState() => _JoinLeagueScreenState();
}

class _JoinLeagueScreenState extends State<JoinLeagueScreen> {
  final _codeController = TextEditingController();
  final Strategy strategy = Strategy.P2P_POINT_TO_POINT;
  bool isScanning = false;

  @override
  void dispose() {
    Nearby().stopDiscovery();
    super.dispose();
  }

  Future<void> _startBluetoothDiscovery() async {
    if (isScanning) {
      await Nearby().stopDiscovery();
      setState(() { isScanning = false; });
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stopped Scanning")));
      return;
    }

    if (!await _checkPermissions()) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Permissions denied for Bluetooth")));
       return;
    }

    try {
      bool success = await Nearby().startDiscovery(
        "Guest User", 
        strategy,
        onEndpointFound: (String id, String userName, String serviceId) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Found Host: $userName. Connecting...")));
           
           Nearby().requestConnection(
             "Guest User", 
             id, 
             onConnectionInitiated: (id, info) {
               Nearby().acceptConnection(
                 id, 
                 onPayLoadRecieved: (endId, payload) {
                   if (payload.type == PayloadType.BYTES) {
                      String code = String.fromCharCodes(payload.bytes!);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Received Code: $code")));
                      
                      setState(() {
                        _codeController.text = code;
                      });
                      
                      // Auto Stop
                      Nearby().stopDiscovery();
                      Nearby().stopAllEndpoints();
                      setState(() { isScanning = false; });

                      _attemptJoin();
                   }
                 }
               );
             }, 
             onConnectionResult: (id, status) {
               if (status == Status.CONNECTED) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connected! Waiting for code...")));
               }
             },
             onDisconnected: (id) {}
           );
        },
        onEndpointLost: (id) {},
      );

      setState(() { isScanning = success; });
      if (success) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Scanning for League Hosts...")));
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
      Permission.nearbyWifiDevices,
      Permission.camera
    ].request();
    
    return !statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied);
  }

  Future<void> _scanQrCode() async {
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Camera permission needed for QR Scan")));
      return;
    }

    final result = await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("Scan QR Code")),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                 Navigator.pop(context, barcodes.first.rawValue);
              }
            },
          ),
        )
      )
    );

    if (result != null && result is String) {
       setState(() {
         _codeController.text = result;
       });
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("QR Code Scanned: $result")));
       _attemptJoin();
    }
  }

  Future<void> _attemptJoin() async {
    String code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a code."), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      bool success = await AppData().joinLeague(code);
      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Joined League Successfully!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not join. Check if code is valid or network."), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
       if (!mounted) return;
       String msg = "Error: $e";
       if (e.toString().contains("ALREADY_JOINED")) {
         msg = "You are already in this league!";
       }
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: e.toString().contains("ALREADY_JOINED") ? Colors.orange : Colors.red),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.grey[300], 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2A0D55)), 
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Enter Code Manually",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A0D55), 
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: "Input",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                          ),
                        ),
                        
                        const SizedBox(height: 50),
                        Center(
                          child: _buildCustomTileButton(
                            context,
                            textLine1: isScanning ? "Stop" : "Join with",
                            textLine2: isScanning ? "Scanning" : "Bluetooth",
                            icon: isScanning ? Icons.stop_circle_outlined : Icons.bluetooth,
                            onPressed: _startBluetoothDiscovery,
                            isActive: isScanning,
                          ),
                        ),

                        if (isScanning)
                           const Padding(
                             padding: EdgeInsets.only(top: 20),
                             child: Center(child: CircularProgressIndicator()),
                           ),

                        const SizedBox(height: 20),
                        Center(
                          child: _buildCustomTileButton(
                            context,
                            textLine1: "Scan",
                            textLine2: "QR Code",
                            icon: Icons.qr_code_scanner,
                            onPressed: _scanQrCode,
                          ),
                        ),

                        const Spacer(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 140,
                            height: 70,
                            child: ElevatedButton(
                              onPressed: _attemptJoin, 
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A0D55),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Join", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text("League", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildCustomTileButton(
    BuildContext context, {
    required String textLine1,
    required String textLine2,
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return SizedBox(
      width: 220,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.redAccent : const Color(0xFF2A0D55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(textLine1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(textLine2, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 30),
          ],
        ),
      ),
    );
  }
}