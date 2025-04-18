import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_network/theme/theme_provider.dart';

import '../Controller/profile_controller.dart';
import '../models/profile_model.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileController(profileModel: ProfileModel()),
      child: const _ProfileScreenView(),
    );
  }
}

class _ProfileScreenView extends StatefulWidget {
  const _ProfileScreenView();

  @override
  _ProfileScreenViewState createState() => _ProfileScreenViewState();
}

class _ProfileScreenViewState extends State<_ProfileScreenView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileController>(context, listen: false).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProfileController>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Stack(
        children: [
          controller.isLoading
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
                      backgroundColor: Colors.grey,
                      child: ClipOval(
                        child: controller.image != null
                            ? Image.file(
                          controller.image!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                            : controller.profilePic.isNotEmpty
                            ? Image.network(
                          controller.profilePic,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: controller.pickImageAndUpload,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  controller.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  controller.email,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
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
                  onPressed: () => controller.logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      controller.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          if (controller.isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}