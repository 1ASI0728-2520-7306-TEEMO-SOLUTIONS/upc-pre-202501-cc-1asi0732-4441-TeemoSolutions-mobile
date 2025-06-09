class UserModel {
  final String id;
  final String username;
  final String name;
  final String role;
  final String? token; // puede ser null

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.token,
  });

   String get formattedRole {
    // Por ejemplo, capitalizar la primera letra
    if (role.isEmpty) return '';
    return role[0].toUpperCase() + role.substring(1);
  }
  
  // Calcula iniciales desde el nombre o username
  String get initials {
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? json['username'] ?? '',
      role: json['role'] ?? 'ROLE_USER',
      token: json['token'], // puede ser null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'role': role,
      'token': token,
    };
  }
}
