import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/config.dart';

class ChatModel {
  IO.Socket? _socket;

  Future<Map<String, dynamic>> fetchChats() async {
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
        Uri.parse('${Config.baseUrl}/api/messages/latest-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return {
            'success': true,
            'data': data,
          };
        } else {
          return {
            'success': false,
            'message': 'Invalid data format.',
            'data': [],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load chats: ${response.statusCode}',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching chats: $e',
        'data': [],
      };
    }
  }

  Future<Map<String, dynamic>> fetchMessages(String userId) async {
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
        Uri.parse('${Config.baseUrl}/api/messages/$userId'),
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
          'message': 'Failed to load messages: ${response.statusCode}',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching messages: $e',
        'data': [],
      };
    }
  }

  Future<Map<String, dynamic>> sendMessage(String userId, String messageText) async {
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
        Uri.parse('${Config.baseUrl}/api/messages/send/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'text': messageText, 'image': ''}),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send message: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error sending message: $e',
      };
    }
  }

  Future<String> getProfilePic() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pic') ?? '';
  }

  void connectSocket(String userId, String token, String chatUserId, Function(dynamic) onNewMessage) {
    _socket = IO.io(Config.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'userId': userId},
      'extraHeaders': {'Authorization': 'Bearer $token'},
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ Connected to WebSocket: ${_socket!.id}');
      _socket!.emit('joinChat', chatUserId);
    });

    _socket!.on('newMessage', (data) {
      print('📩 New message: $data');
      onNewMessage(data);
    });

    _socket!.onDisconnect((_) {
      print('❌ Disconnected from WebSocket');
    });
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
  }
}