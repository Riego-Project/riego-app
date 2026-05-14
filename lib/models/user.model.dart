class UserModel {
  final String token;
  final String nombre;
  final String email;

  const UserModel({
    required this.token,
    required this.nombre,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      token:  json['token']  as String,
      nombre: json['nombre'] as String,
      email:  json['email']  as String,
    );
  }
}