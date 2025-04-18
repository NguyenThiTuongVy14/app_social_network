import 'dart:io';
import 'package:flutter/material.dart';

import '../models/profile_model.dart';

class ProfileController extends ChangeNotifier {
  final ProfileModel profileModel;
  String _name = 'Unknown';
  String _email = 'No email';
  String _profilePic = '';
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;
  File? _image;

  ProfileController({required this.profileModel});

  String get name => _name;
  String get email => _email;
  String get profilePic => _profilePic;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  File? get image => _image;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await profileModel.fetchProfile();
    if (result['success']) {
      _name = result['data']['name'];
      _email = result['data']['email'];
      _profilePic = result['data']['profilePic'];
    } else {
      _errorMessage = 'Failed to load profile';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> pickImageAndUpload() async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await profileModel.pickImageAndUpload();
    if (result['success']) {
      _profilePic = result['data']['profilePic'];
      _image = File(result['data']['localPath']);
      _errorMessage = result['message'];
    } else {
      _errorMessage = result['message'];
    }

    _isUploading = false;
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    final result = await profileModel.logout();
    if (result['success']) {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      _errorMessage = 'Failed to logout';
      notifyListeners();
    }
  }
}