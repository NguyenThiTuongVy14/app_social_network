import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Controller/chat_controller.dart';
import '../models/chat_model.dart';


class ChatScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatController(
        chatModel: ChatModel(),
        userId: userId,
      ),
      child: _ChatScreenView(
        userId: userId,
        userName: userName,
        profilePic: profilePic,
      ),
    );
  }
}

class _ChatScreenView extends StatefulWidget {
  final String userId;
  final String userName;
  final String profilePic;

  const _ChatScreenView({
    required this.userId,
    required this.userName,
    required this.profilePic,
  });

  @override
  _ChatScreenViewState createState() => _ChatScreenViewState();
}

class _ChatScreenViewState extends State<_ChatScreenView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ChatController>(context, listen: false);
      controller.fetchProfilePic();
      controller.fetchMessages();
      _initializeSocket(controller);
    });
  }

  Future<void> _initializeSocket(ChatController controller) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final currentUserId = prefs.getString('id') ?? '';
    controller.connectSocket(token, currentUserId);
  }

  @override
  void dispose() {
    Provider.of<ChatController>(context, listen: false).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ChatController>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
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
              child: ClipOval(
                child: widget.profilePic.isNotEmpty
                    ? Image.network(
                  widget.profilePic,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Text(
                    widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                )
                    : Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
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
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.grey))
                    : ListView.builder(
                  controller: controller.scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];
                    final isMe = message['senderId'] != widget.userId;

                    return Row(
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isMe)
                          CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: ClipOval(
                              child: widget.profilePic.isNotEmpty
                                  ? Image.network(
                                widget.profilePic,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Text(
                                  widget.userName.isNotEmpty
                                      ? widget.userName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              )
                                  : Text(
                                widget.userName.isNotEmpty
                                    ? widget.userName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
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
                        const SizedBox(width: 5),
                        if (isMe)
                          CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: ClipOval(
                              child: controller.myProfilePic.isNotEmpty
                                  ? Image.network(
                                controller.myProfilePic,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Text(
                                  'Me',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              )
                                  : Text(
                                'Me',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
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
                        controller: controller.messageController,
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
                              : Colors.grey[200],
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
                      onPressed: controller.sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (controller.errorMessage != null)
            Positioned(
              bottom: 60,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}