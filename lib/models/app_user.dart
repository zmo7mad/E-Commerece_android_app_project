class AppUser {
AppUser({
  required this.uid,
  required this.name,
  required this.email,
  required this.address,
});


final String uid;
final String name;
final String email;
final String address;


  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      address: map['address'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'address': address,
    };
  }



}