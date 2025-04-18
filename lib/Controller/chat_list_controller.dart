import 'package:flutter/material.dart';
import '../models/chat_model.dart';

class ChatListController extends ChangeNotifier {
  final ChatModel chatModel;
  List<dynamic> _chatList = [];
  bool _isLoading = true;
  String? _errorMessage;

  ChatListController({required this.chatModel});

  List<dynamic> get chatList => _chatList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchChats(BuildContext context, {bool showError = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await chatModel.fetchChats();

    _chatList = result['data'];
    _isLoading = false;

    if (!result['success'] && showError) {
      _errorMessage = result['message'];
    }

    notifyListeners();
  }

  Future<void> refreshChats(BuildContext context) async {
    await fetchChats(context, showError: false);
  }
}