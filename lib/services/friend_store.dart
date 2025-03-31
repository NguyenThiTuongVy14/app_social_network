import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_network/config/config.dart';

class FriendStore extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(baseUrl: "${Config.baseUrl}/api/friends"));
  List<dynamic> friends = [];
  List<dynamic> requestsFriend = [];
  List<dynamic> invitatesFriend = [];
  String? _token;

  FriendStore() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    notifyListeners();
  }

  Future<void> _fetchData(String endpoint, List<dynamic> list) async {
    if (_token == null || _token!.isEmpty) {
      print('No token found');
      return;
    }

    try {
      final response = await _dio.get(endpoint, options: Options(headers: {
        "Authorization": "Bearer $_token"
      }));

      if (response.statusCode == 200) {
        list.clear();
        list.addAll(response.data);
        notifyListeners();
      }
    } catch (error) {
      print("Error fetching $endpoint: $error");
    }
  }

  Future<void> getFriends() async {
    await _fetchData("/friends", friends);
  }

  Future<void> getRequestFriends() async {
    await _fetchData("/get-requests", requestsFriend);
  }

  Future<void> getInvitateFriends() async {
    await _fetchData("/get-invitates", invitatesFriend);
  }

  Future<void> sendRequest(String receiverId) async {
    if (_token == null || _token!.isEmpty) return;

    try {
      final response = await _dio.post("/send-requests",
          data: {"idReceiver": receiverId},
          options: Options(headers: {"Authorization": "Bearer $_token"}));

      if (response.statusCode == 200) {
        getRequestFriends();
      }
    } catch (error) {
      print("Error sending friend request: $error");
    }
  }

  Future<void> removeFriend(String friendId) async {
    if (_token == null || _token!.isEmpty) return;

    try {
      final response = await _dio.post("/remove-friend",
          data: {"idRemove": friendId},
          options: Options(headers: {"Authorization": "Bearer $_token"}));

      if (response.statusCode == 200) {
        getFriends();
      }
    } catch (error) {
      print("Error removing friend: $error");
    }
  }

  Future<void> acceptFriend(String friendId) async {
    if (_token == null || _token!.isEmpty) return;

    try {
      final response = await _dio.post("/accept-friend",
          data: {"idAccept": friendId},
          options: Options(headers: {"Authorization": "Bearer $_token"}));

      if (response.statusCode == 201) {
        getFriends();
        getInvitateFriends();
      }
    } catch (error) {
      print("Error accepting friend: $error");
    }
  }

  Future<void> cancelRequest(String requestId) async {
    if (_token == null || _token!.isEmpty) return;

    try {
      final response = await _dio.post("/cancle-request",
          data: {"idCancle": requestId},
          options: Options(headers: {"Authorization": "Bearer $_token"}));

      if (response.statusCode == 201) {
        getRequestFriends();
      }
    } catch (error) {
      print("Error canceling request: $error");
    }
  }
}
