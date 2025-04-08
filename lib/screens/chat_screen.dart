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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white, // Nền trắng/đen theo theme
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
        elevation: 1,
        shadowColor: Colors.grey,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage: widget.profilePic.isNotEmpty
                  ? NetworkImage(widget.profilePic)
                  : null,
              child: widget.profilePic.isEmpty
                  ? Text(
                widget.userName[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.userName,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? Center(
              child: CircularProgressIndicator(
                color: Colors.grey, // Loading xám
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe = message['senderId'] != widget.userId;

                return Row(
                  mainAxisAlignment: isMe
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!isMe)
                      CircleAvatar(
                        backgroundColor: Colors.grey, // Avatar xám
                        backgroundImage: NetworkImage(widget.profilePic),
                      ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? (isMe ? Colors.grey[800] : Colors.grey[600])
                              : (isMe ? Colors.grey[300] : Colors.grey[500]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message['text'],
                          softWrap: true,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5,),
                    if (isMe)
                      CircleAvatar(
                        backgroundColor: Colors.grey,
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
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.grey[200], // Nền TextField xám
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
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