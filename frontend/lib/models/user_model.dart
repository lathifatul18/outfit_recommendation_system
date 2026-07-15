/// User model
class UserModel {
  final int idUser;
  final String nama;
  final String username;
  final String email;

  const UserModel({
    required this.idUser,
    required this.nama,
    required this.username,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUser: json['id_user'] as int,
      nama: json['nama'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'nama': nama,
      'username': username,
      'email': email,
    };
  }
}
