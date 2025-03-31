import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:social_network/screens/chat_screen.dart';

class ChatItem extends StatelessWidget {
  final String userId;
  final String name;
  final String profilePic;
  final String lastMessage;
  final String lastMessageTime;

  const ChatItem({
    super.key,
    required this.userId,
    required this.name,
    required this.profilePic,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  // Hàm hiển thị thời gian dưới dạng "X phút trước", "X giờ trước", "X ngày trước"
  String formatTime(String isoTime) {
    DateTime messageTime = DateTime.parse(isoTime).toLocal();
    DateTime now = DateTime.now();
    Duration difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return "Vừa xong";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} phút trước";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} giờ trước";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} ngày trước";
    } else {
      return DateFormat('dd/MM/yyyy').format(messageTime); // Hiển thị ngày nếu quá 1 tuần
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade200,
          backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
          child: profilePic.isEmpty
              ? Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          )
              : null,
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              formatTime(lastMessageTime), // Hiển thị kiểu "X phút trước"
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                userId: userId,
                userName: name,
                profilePic: profilePic,
              ),
            ),
          );
        },
      ),
    );
  }
}
