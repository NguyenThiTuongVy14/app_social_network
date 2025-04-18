import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_network/widgets/chat_item.dart';

import '../Controller/chat_list_controller.dart';
import '../models/chat_model.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatListController(chatModel: ChatModel()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messenger'),
        ),
        body: const ChatListPage(),
      ),
    );
  }
}

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

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
    final controller = Provider.of<ChatListController>(context);

    // Gọi fetchChats khi khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.isLoading && controller.chatList.isEmpty) {
        controller.fetchChats(context);
      }
    });

    return RefreshIndicator(
      onRefresh: () => controller.refreshChats(context),
      child: Stack(
        children: [
          if (controller.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (controller.chatList.isEmpty)
            _buildEmptyChat()
          else
            ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: controller.chatList.length,
              itemBuilder: (context, index) {
                final chat = controller.chatList[index];
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
            ),
          if (controller.errorMessage != null)
            Positioned(
              bottom: 16,
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