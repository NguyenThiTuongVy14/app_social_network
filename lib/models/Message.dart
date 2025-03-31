class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String? text;
  final String? image;
  final bool isDelete;
  final bool isRevoke;
  final String createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.text,
    this.image,
    this.isDelete = false,
    this.isRevoke = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      text: json['text'],
      image: json['image'],
      isDelete: json['isDelete'] ?? false,
      isRevoke: json['isRevoke'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'image': image,
      'isDelete': isDelete,
      'isRevoke': isRevoke,
      'createdAt': createdAt,
    };
  }
}