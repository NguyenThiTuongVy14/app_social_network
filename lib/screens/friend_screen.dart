import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_network/screens/chat_screen.dart';

import '../Controller/friend_controller.dart';
import '../models/friend_model.dart';

class FriendScreen extends StatelessWidget {
  const FriendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FriendController(friendModel: FriendModel()),
      child: const _FriendScreenView(),
    );
  }
}

class _FriendScreenView extends StatefulWidget {
  const _FriendScreenView();

  @override
  _FriendScreenViewState createState() => _FriendScreenViewState();
}

class _FriendScreenViewState extends State<_FriendScreenView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FriendController>(context, listen: false).fetchAllFriendData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget buildSearchResult(FriendController controller) {
    final searchResult = controller.searchResult;
    if (searchResult == null) return const SizedBox.shrink();

    if (searchResult.containsKey('message')) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(searchResult['message'], style: const TextStyle(color: Colors.red)),
      );
    }

    final String type = searchResult['type'] ?? 'stranger';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey,
        child: ClipOval(
          child: searchResult['profilePic']?.isNotEmpty == true
              ? Image.network(
            searchResult['profilePic'],
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Text(
              searchResult['fullName']?.isNotEmpty == true
                  ? searchResult['fullName'][0].toUpperCase()
                  : '?',
              style: const TextStyle(color: Colors.white),
            ),
          )
              : Text(
            searchResult['fullName']?.isNotEmpty == true
                ? searchResult['fullName'][0].toUpperCase()
                : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      title: Text(searchResult['fullName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(searchResult['email'] ?? 'No email', style: const TextStyle(color: Colors.grey)),
      trailing: type == "stranger"
          ? IconButton(
        icon: const Icon(Icons.person_add, color: Colors.green),
        onPressed: () => controller.handleFriendAction('send-requests',
            body: {'idReceiver': '${searchResult['_id']}'}),
      )
          : null,
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
    final controller = Provider.of<FriendController>(context, listen: false);

    return ListTile(
      onTap: () {
        if (isFriend) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                userId: user['_id'],
                userName: fullName,
                profilePic: profilePic,
              ),
            ),
          );
        }
      },
      leading: CircleAvatar(
        backgroundColor: Colors.grey,
        child: ClipOval(
          child: profilePic.isNotEmpty
              ? Image.network(
            profilePic,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Text(
              fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          )
              : Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(email, style: const TextStyle(color: Colors.grey)),
      trailing: isFriend
          ? IconButton(
        icon: const Icon(Icons.person_remove, color: Colors.red),
        onPressed: () => controller.handleFriendAction('remove-friend',
            body: {'idRemove': '${user['_id']}'}),
      )
          : isInvite
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => controller.handleFriendAction('accept-friend',
                body: {'idAccept': '${user['_id']}'}),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () =>
                controller.handleFriendAction('decline-friend/${user['_id']}'),
          ),
        ],
      )
          : IconButton(
        icon: const Icon(Icons.cancel, color: Colors.orange),
        onPressed: () => controller.handleFriendAction('cancle-request',
            body: {'idCancle': '${user['_id']}'}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FriendController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Friends")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: controller.searchController,
                  decoration: InputDecoration(
                    hintText: "Search friends by email...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    suffixIcon: controller.searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: controller.clearSearch,
                    )
                        : null,
                  ),
                  onChanged: controller.searchUser,
                ),
                if (controller.isSearching)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )
                else
                  buildSearchResult(controller),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: "Friends"), Tab(text: "Invites"), Tab(text: "Sent")],
          ),
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                buildFriendList(controller.friends, isFriend: true),
                buildFriendList(controller.invites, isInvite: true),
                buildFriendList(controller.sentRequests),
              ],
            ),
          ),
          if (controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                controller.errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}