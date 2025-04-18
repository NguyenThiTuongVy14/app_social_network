import 'package:flutter/material.dart';

import '../models/friend_model.dart';

class FriendController extends ChangeNotifier {
  final FriendModel friendModel;
  List<dynamic> _friends = [];
  List<dynamic> _invites = [];
  List<dynamic> _sentRequests = [];
  Map<String, dynamic>? _searchResult;
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;
  final TextEditingController searchController = TextEditingController();

  FriendController({required this.friendModel});

  List<dynamic> get friends => _friends;
  List<dynamic> get invites => _invites;
  List<dynamic> get sentRequests => _sentRequests;
  Map<String, dynamic>? get searchResult => _searchResult;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAllFriendData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final responses = await Future.wait([
        friendModel.fetchFriends(),
        friendModel.fetchInvites(),
        friendModel.fetchRequests(),
      ]);

      _friends = responses[0]['success'] ? responses[0]['data'] : [];
      _invites = responses[1]['success'] ? responses[1]['data'] : [];
      _sentRequests = responses[2]['success'] ? responses[2]['data'] : [];

      if (!responses[0]['success'] || !responses[1]['success'] || !responses[2]['success']) {
        _errorMessage = 'Failed to load some data';
      }
    } catch (e) {
      _errorMessage = 'Error fetching data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchUser(String email) async {
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    final result = await friendModel.searchUser(email);
    _searchResult = result['data'];

    if (!result['success']) {
      _errorMessage = result['message'];
    }

    _isSearching = false;
    notifyListeners();
  }

  Future<void> handleFriendAction(String endpoint, {Map<String, dynamic>? body}) async {
    final result = await friendModel.handleFriendAction(endpoint, body: body);

    if (!result['success']) {
      _errorMessage = result['message'];
      notifyListeners();
    } else {
      await fetchAllFriendData();
    }
  }

  void clearSearch() {
    searchController.clear();
    _searchResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}