import 'package:flutter/material.dart';

import '../models/chat_model.dart';

class ChatController extends ChangeNotifier {
  final ChatModel chatModel;
  final String userId;
  List<dynamic> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _myProfilePic = '';
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  ChatController({required this.chatModel, required this.userId});

  List<dynamic> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get myProfilePic => _myProfilePic;

  Future<void> fetchMessages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await chatModel.fetchMessages(userId);
    _messages = result['data'];
    _isLoading = false;

    if (!result['success']) {
      _errorMessage = result['message'];
    }

    notifyListeners();
    if (_messages.isNotEmpty) {
      scrollToBottom();
    }
  }

  Future<void> fetchProfilePic() async {
    _myProfilePic = await chatModel.getProfilePic();
    notifyListeners();
  }

  Future<void> sendMessage() async {
    final messageText = messageController.text.trim();
    if (messageText.isEmpty) return;

    final result = await chatModel.sendMessage(userId, messageText);

    if (result['success']) {
      _messages.add(result['data']);
      messageController.clear();
      notifyListeners();
      scrollToBottom();
    } else {
      _errorMessage = result['message'];
      notifyListeners();
    }
  }

  void connectSocket(String token, String currentUserId) {
    chatModel.connectSocket(currentUserId, token, userId, (data) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messages.add(data);
        notifyListeners();
        scrollToBottom();
      });
    });
  }

  void scrollToBottom() {
    if (_messages.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients && scrollController.position.hasContentDimensions) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    chatModel.disconnectSocket();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}