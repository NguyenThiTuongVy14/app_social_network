class User{
   final String id;
   final String email;
   final String fullName;
   final String profilePic;
   final List<String> friends;
   final List<String> requestFriend;
   final List<String> invitateFriend;

  User({required this.id,required this.email,required this.fullName, this.profilePic="", this.friends=const [],
      this.requestFriend=const [], this.invitateFriend=const []});

  factory User.fromJson(Map<String, dynamic> json){
    return User(
        id: json['_id'] ?? '',
        email: json['email'] ?? '',
        fullName: json['fullName'] ?? 'Unknow',
        profilePic: json['profilePic'] ?? '',
        friends: List<String>.from(json['friends'] ?? []),
        requestFriend: List<String>.from(json['requestFriend'] ?? []),
        invitateFriend: List<String>.from(json['invitateFriend'] ?? []),
    );
  }
   Map<String, dynamic> toJson() {
     return {
       '_id': id,
       'email': email,
       'fullName': fullName,
       'profilePic': profilePic,
       'friends': friends,
       'requestFriend': requestFriend,
       'invitateFriend': invitateFriend,
     };
   }
}