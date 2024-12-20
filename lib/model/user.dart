import 'dart:convert';

User UserFromJson(String str) {
  final jsonData = json.decode(str);
  return User.fromMap(jsonData);
}

String UserToJson(User data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class User {
  int id;
  int uid;
  String nik;
  String nama;
  String email;
  int role;
  int status;

  User({
    required this.id,
    required this.uid,
    required this.nik,
    required this.nama,
    required this.email,
    required this.role,
    required this.status,
  });

  factory User.fromMap(Map<String, dynamic> json) => User(
    id: json["id"],
    uid: json["uid"],
    nik: json["nik"],
    nama: json["nama"],
    email: json["email"],
    role: json["role"],
    status: json["status"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "uid": uid,
    "nik": nik,
    "nama": nama,
    "email": email,
    "role": role,
    "status": status,
  };
}
