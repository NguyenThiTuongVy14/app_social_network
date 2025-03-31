import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:social_network/config/config.dart';
import 'package:social_network/screens/chat_screen.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  _FriendScreenState createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> friends = [];
  List<dynamic> invites = [];
  List<dynamic> sentRequests = [];
  Map<String, dynamic>? searchResult;
  bool isLoading = true;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchAllFriendData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchAllFriendData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${Config.baseUrl}/api/friend/friends'),
            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}),
        http.get(Uri.parse('${Config.baseUrl}/api/friend/get-invitates'),
            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}),
        http.get(Uri.parse('${Config.baseUrl}/api/friend/get-requests'),
            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}),
      ]);

      setState(() {
        friends = responses[0].statusCode == 200 ? json.decode(responses[0].body) : [];
        invites = responses[1].statusCode == 200 ? json.decode(responses[1].body) : [];
        sentRequests = responses[2].statusCode == 200 ? json.decode(responses[2].body) : [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> searchUser(String email) async {
    if (email.isEmpty) {
      setState(() {
        searchResult = null;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) return;

    setState(() {
      isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/friend/search/$email'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          searchResult = json.decode(response.body);
        });
      } else {
        setState(() {
          searchResult = {'message': 'User not found'};
        });
      }
    } catch (e) {
      setState(() {
        searchResult = {'message': 'Error searching user'};
      });
    } finally {
      setState(() {
        isSearching = false;
      });
    }
  }

  Future<void> handleFriendAction(String endpoint, {Map<String, dynamic>? body}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) return;

    try {
      await http.post(
        Uri.parse('${Config.baseUrl}/api/friend/$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body != null ? jsonEncode(body) : null,
      );
      fetchAllFriendData();
    } catch (e) {}
  }

  Widget buildSearchResult() {
    if (searchResult == null) return const SizedBox.shrink();

    if (searchResult!.containsKey('message')) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(searchResult!['message'], style: const TextStyle(color: Colors.red)),
      );
    }

    final user = searchResult!;
    final String type = user['type'] ?? 'stranger';

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user['profilePic']?.isNotEmpty == true
            ? NetworkImage(user['profilePic'])
            : const AssetImage('assets/default_avatar.png') as ImageProvider,
      ),
      title: Text(user['fullName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(user['email'] ?? 'No email', style: const TextStyle(color: Colors.grey)),
      trailing: type == "stranger"
          ? IconButton(
        icon: const Icon(Icons.person_add, color: Colors.green),
        onPressed: () => handleFriendAction('send-requests', body: {'idReceiver': '${user['_id']}'}),
      )
          : null
    );
  }

  Widget buildFriendList(List<dynamic> list, {bool isFriend = false, bool isInvite = false}) {
    return list.isEmpty
        ? const Center(child: Text("No data found."))
        : ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final user = list[index];
        return buildUserTile(user, isFriend: isFriend, isInvite: isInvite);
      },
    );
  }

  Widget buildUserTile(Map<String, dynamic> user, {bool isFriend = false, bool isInvite = false}) {
    final String fullName = user['fullName'] ?? 'Unknown';
    final String email = user['email'] ?? 'No email';
    final String profilePic = user['profilePic'] ?? '';

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: profilePic.isNotEmpty
            ? NetworkImage(profilePic)
            : const AssetImage('assets/default_avatar.png') as ImageProvider,
      ),
      title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(email, style: const TextStyle(color: Colors.grey)),
      trailing: isFriend
          ? IconButton(
        icon: const Icon(Icons.person_remove, color: Colors.red),
        onPressed: () => handleFriendAction('remove-friend', body: {'idRemove': '${user['_id']}'}),
      )
          : isInvite
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => handleFriendAction('accept-friend', body: {'idAccept': '${user['_id']}'}),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => handleFriendAction('decline-friend/${user['_id']}'),
          ),
        ],
      )
          : IconButton(
        icon: const Icon(Icons.cancel, color: Colors.orange),
        onPressed: () => handleFriendAction('cancle-request', body: {'idCancle': '${user['_id']}'}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Friends")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search friends by email...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (value) => searchUser(value),
                ),
                buildSearchResult(),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: "Friends"), Tab(text: "Invites"), Tab(text: "Sent")],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildFriendList(friends, isFriend: true),
                buildFriendList(invites, isInvite: true),
                buildFriendList(sentRequests),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
