import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_network/config/config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String profilePic;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.profilePic,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> messages = [];
  bool isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  IO.Socket? socket;
  String myProfilePic = '';

  @override
  void initState() {
    super.initState();
    fetchProfilePic();
    fetchMessages();
    connectSocket();
  }

  Future<void> fetchProfilePic() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myProfilePic = prefs.getString('pic') ?? '';
    });
  }

  void scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> fetchMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      print('No token found');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/messages/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          messages = json.decode(response.body);
          isLoading = false;
        });
        scrollToBottom();
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching messages: $e');
    }
  }

  void connectSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final id = prefs.getString('id') ?? '';
    socket = IO.io(Config.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'userId': id},
      'extraHeaders': {'Authorization': 'Bearer $token'},
    });

    socket!.connect();

    socket!.onConnect((_) {
      print('✅ Connected to WebSocket: ${socket!.id}');
      socket!.emit('joinChat', widget.userId);
    });

    socket!.on('newMessage', (data) {
      print('📩 New message: $data');
      if (mounted) {
        setState(() {
          messages.add(data);
        });
        scrollToBottom();
      }
    });

    socket!.onDisconnect((_) {
      print('❌ Disconnected from WebSocket');
    });
  }

  Future<void> sendMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final messageText = _messageController.text.trim();

    if (messageText.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/messages/send/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'text': messageText, 'image': ''}),
      );

      if (response.statusCode == 201) {
        final newMessage = json.decode(response.body);
        setState(() {
          messages.add(newMessage);
        });

        _messageController.clear();
        scrollToBottom();
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.profilePic.isNotEmpty
                  ? NetworkImage(widget.profilePic)
                  : null,
              child: widget.profilePic.isEmpty
                  ? Text(widget.userName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 10),
            Text(widget.userName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe = message['senderId'] != widget.userId;

                return Row(
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isMe)
                      CircleAvatar(
                        backgroundImage: NetworkImage(widget.profilePic),
                      ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.purple.shade100 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(message['text'],),
                    ),
                    if (isMe)
                      CircleAvatar(
                        backgroundImage: myProfilePic.isNotEmpty
                            ? NetworkImage(myProfilePic)
                            : null,
                      ),
                  ],
                );

              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
