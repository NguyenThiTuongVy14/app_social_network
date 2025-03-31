import 'package:social_network/config/config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connectSocket(String userId) {
    socket = IO.io('${Config.baseUrl}', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'userId': userId}
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to socket.io server');
    });

    socket.onDisconnect((_) {
      print('Disconnected from socket.io server');
    });

    socket.on("newMessage", (data) {
      print("Received new message: $data");
      // Cập nhật danh sách tin nhắn
    });
  }

  void sendMessage(String receiverId, String text, String image) {
    socket.emit('sendMessage', {
      "receiverId": receiverId,
      "text": text,
      "image": image
    });
  }

  void disconnectSocket() {
    socket.disconnect();
  }
}
