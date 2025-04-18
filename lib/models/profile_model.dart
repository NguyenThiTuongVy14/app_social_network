import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';

class ProfileModel {
  Future<Map<String, dynamic>> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'success': true,
      'data': {
        'name': prefs.getString('name') ?? 'Unknown',
        'email': prefs.getString('email') ?? 'No email',
        'profilePic': prefs.getString('pic') ?? '',
      },
    };
  }

  Future<Map<String, dynamic>> pickImageAndUpload() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return {
        'success': false,
        'message': 'No image selected',
      };
    }

    try {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,' + base64Encode(bytes);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        return {
          'success': false,
          'message': 'No token found. Please log in again.',
        };
      }

      final response = await http.put(
        Uri.parse('${Config.baseUrl}/api/auth/update-profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'profilePic': base64Image}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('pic', data['profilePic'] ?? '');
        return {
          'success': true,
          'data': {
            'profilePic': data['profilePic'] ?? '',
            'localPath': pickedFile.path,
          },
          'message': 'Cập nhật ảnh đại diện thành công',
        };
      } else {
        return {
          'success': false,
          'message': 'Cập nhật thất bại',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Có lỗi xảy ra khi cập nhật: $e',
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    return {
      'success': true,
      'message': 'Đăng xuất thành công',
    };
  }
}