import 'package:flutter/material.dart';
import 'package:social_network/screens/chat_screen.dart'; // Thêm dòng này
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_network/config/config.dart';

import '../widgets/chat_item.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messenger'),
      ),
      body: const ChatListPage(),
    );
  }
}

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<dynamic> chatList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Future<void> fetchChats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    print('Token from prefs: $token');
    if (token.isEmpty) {
      print('No token found');
      return;
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
          setState(() {
            chatList = data;
            isLoading = false;
          });
        } else {
          throw Exception('Invalid data format');
        }
      } else {
        throw Exception('Failed to load chats: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching chats: $e');
    }
  }
  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Chưa có tin nhắn",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Hãy bắt đầu cuộc trò chuyện với bạn bè!",
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chatList.isEmpty) {
      return _buildEmptyChat();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: chatList.length,
      itemBuilder: (context, index) {
        final chat = chatList[index];
        return ChatItem(
          userId: chat['userId']?.toString() ?? '',
          name: chat['fullName']?.toString() ?? 'Unknown',
          profilePic: chat['profilePic']?.toString() ?? '',
          lastMessage: chat['lastMessage'] != null
              ? chat['lastMessage']['text']?.toString() ?? ''
              : 'No messages yet',
          lastMessageTime: chat['lastMessage'] != null
              ? chat['lastMessage']['createdAt']?.toString() ?? ''
              : '',
        );
      },
    );
  }
}
