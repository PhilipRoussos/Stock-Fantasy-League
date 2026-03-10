import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  void _showEditProfileDialog(BuildContext context) {
    TextEditingController usernameController = TextEditingController(text: AppData().currentUserName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("New Username:", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2A0D55))),
              const SizedBox(height: 10),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(hintText: "Input", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
              ),
              const SizedBox(height: 20),
              const Text("New Profile Pic", style: TextStyle(fontSize: 18, color: Color(0xFF2A0D55))),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF2A0D55)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Gallery"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF2A0D55)),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: SizedBox(
                  width: 150, height: 45,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (usernameController.text.isNotEmpty) {
                        String newName = usernameController.text.trim();
                        
                        try {
                          await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
                          await FirebaseAuth.instance.currentUser?.reload(); 
                        } catch (e) {
                          print("Error updating firebase profile: $e");
                        }

                        await AppData().updateUserName(newName);
                        
                        setState(() {}); 
                      }
                      
                      if (context.mounted) {
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!")));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A0D55), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    child: const Text("Confirm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      AppData().currentProfilePic = image.path;
      AppData().saveLeaguesToStorage(); 
      setState(() {}); 
      if (mounted) Navigator.pop(context); 
    }
  }

  ImageProvider? _getProfileImage() {
    if (AppData().currentProfilePic != null) {
      return FileImage(File(AppData().currentProfilePic!));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String email = user?.email ?? "";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("PROFILE", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2A0D55))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFFE0E0E0),
              backgroundImage: _getProfileImage(),
              child: AppData().currentProfilePic == null 
                  ? const Icon(Icons.person_outline, size: 60, color: Color(0xFF2A0D55)) 
                  : null,
            ),
            const SizedBox(height: 10),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppData().currentUserName, 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2A0D55))
                ),
                const SizedBox(width: 5),
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: Colors.grey[600]), 
                  onPressed: () => _showEditProfileDialog(context)
                ),
              ],
            ),
            
            if (email.isNotEmpty)
              Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 14)),

            const SizedBox(height: 30),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2A0D55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildStatRow("Total Leagues: ${AppData().leagues.length}"),
                  const Divider(color: Colors.white54, thickness: 1.5),

                  _buildSwitchRow(
                    "Sound", 
                    AppData().isSoundOn, 
                    (val) {
                      setState(() {
                        AppData().isSoundOn = val;
                        AppData().saveLeaguesToStorage();
                      });
                    }
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  _buildSwitchRow(
                    "Vibration", 
                    AppData().isVibrationOn, 
                    (val) {
                      setState(() {
                        AppData().isVibrationOn = val;
                        AppData().saveLeaguesToStorage();
                      });
                    }
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: 150, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text("Log out"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.greenAccent,
      activeTrackColor: Colors.greenAccent.withOpacity(0.5),
      inactiveThumbColor: Colors.grey,
      inactiveTrackColor: Colors.white24,
    );
  }
}