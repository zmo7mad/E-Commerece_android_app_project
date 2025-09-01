class AppUser {
AppUser({
  required this.uid,
  required this.name,
  required this.email,
  required this.address,
  required this.userRole,
});


final String uid;
final String name;
final String email;
final String address;
final String userRole; // 'seller' or 'user'


  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      address: map['address'] as String,
      userRole: map['userRole'] as String? ?? 'user', // Default to 'user' if not specified
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'address': address,
      'userRole': userRole,
    };
  }

  // Helper methods to check user role
  bool get isSeller => userRole == 'seller';
  bool get isUser => userRole == 'user';

}