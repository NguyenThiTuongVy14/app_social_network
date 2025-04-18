import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';

class FriendModel {
  Future<Map<String, dynamic>> fetchFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      return {
        'success': false,
        'message': 'No token found. Please log in again.',
        'data': [],
      };
    }

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/friend/friends'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load friends: ${response.statusCode}',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching friends: $e',
        'data': [],
      };
    }
  }

  Future<Map<String, dynamic>> fetchInvites() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      return {
        'success': false,
        'message': 'No token found. Please log in again.',
        'data': [],
      };
    }

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/friend/get-invitates'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load invites: ${response.statusCode}',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching invites: $e',
        'data': [],
      };
    }
  }

  Future<Map<String, dynamic>> fetchRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      return {
        'success': false,
        'message': 'No token found. Please log in again.',
        'data': [],
      };
    }

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/friend/get-requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load requests: ${response.statusCode}',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching requests: $e',
        'data': [],
      };
    }
  }

  Future<Map<String, dynamic>> searchUser(String email) async {
    if (email.isEmpty) {
      return {
        'success': true,
        'data': null,
      };
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      return {
        'success': false,
        'message': 'No token found. Please log in again.',
        'data': null,
      };
    }

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/friend/search/$email'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'User not found',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error searching user: $e',
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> handleFriendAction(String endpoint, {Map<String, dynamic>? body}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      return {
        'success': false,
        'message': 'No token found. Please log in again.',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/friend/$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body != null ? jsonEncode(body) : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to perform action: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error performing action: $e',
      };
    }
  }
}