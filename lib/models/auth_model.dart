import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';

class AuthModel {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${Config.baseUrl}/api/auth/login');
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'email': email,
          'password': password,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['token'];
        final id = responseData['_id'];
        final pic = responseData['profilePic'];
        final name = responseData['fullName'];
        final email = responseData['email'];

        // Lưu dữ liệu vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('id', id);
        await prefs.setString('pic', pic);
        await prefs.setString('name', name);
        await prefs.setString('email', email);

        return {'success': true, 'message': 'Login successful'};
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Login failed, please try again'};
    }
  }

  Future<Map<String, dynamic>> register(
      String fullName, String email, String password) async {
    final url = Uri.parse('${Config.baseUrl}/api/auth/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': fullName,
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Register successful! Please login.'
        };
      } else {
        return {
          'success': false,
          'message': data['msg'] ?? 'Registration failed'
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Something went wrong. Please try again'
      };
    }
  }
}