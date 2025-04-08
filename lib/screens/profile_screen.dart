import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:social_network/screens/login_screen.dart';
import 'package:social_network/theme/theme_provider.dart';
import 'package:social_network/config/config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "";
  String email = "";
  String profilePic = "";
  bool isLoading = true;

  File? _image;
  String? _base64Image;
  bool _uploading = false; // ✅ Loading trạng thái khi upload ảnh

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? 'Unknown';
      email = prefs.getString('email') ?? 'No email';
      profilePic = prefs.getString('pic') ?? '';
      isLoading = false;
    });
  }

  Future<void> pickImageAndUpload() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _uploading = true); // ✅ Bắt đầu loading

    try {
      final bytes = await pickedFile.readAsBytes();
      _base64Image = 'data:image/jpeg;base64,' + base64Encode(bytes);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return;

      final response = await http.put(
        Uri.parse('${Config.baseUrl}/api/auth/update-profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'profilePic': _base64Image}),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          profilePic = data['profilePic'] ?? profilePic;
          _image = File(pickedFile.path);
        });
        await prefs.setString('pic', profilePic);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật ảnh đại diện thành công")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thất bại")),
        );
      }
    } catch (e) {
      print("Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Có lỗi xảy ra khi cập nhật")),
      );
    } finally {
      setState(() => _uploading = false); // ✅ Kết thúc loading
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : (profilePic.isNotEmpty
                          ? NetworkImage(profilePic)
                          : null) as ImageProvider<Object>?,
                      child: profilePic.isEmpty && _image == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: pickImageAndUpload,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wb_sunny, color: Colors.orange),
                    Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: themeProvider.toggleTheme,
                    ),
                    const Icon(Icons.nightlight_round, color: Colors.indigo),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: logout,
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ),
          if (_uploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
