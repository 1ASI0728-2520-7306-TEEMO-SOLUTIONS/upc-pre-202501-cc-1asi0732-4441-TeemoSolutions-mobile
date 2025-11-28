class UserModel {
  final String id;
  final String username;
  final String name;
  final String role; // rol principal (primer rol de la lista)
  final List<String> roles; // lista completa de roles si viene del backend
  final String? token; // puede ser null

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    required this.roles,
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
    // El backend podría mandar 'roles' como lista o un único 'role'.
    final List<String> parsedRoles = (json['roles'] is List)
        ? (json['roles'] as List).whereType<String>().toList()
        : <String>[];
    final primaryRole = parsedRoles.isNotEmpty
        ? parsedRoles.first
        : (json['role'] ?? 'ROLE_USER');
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? json['username'] ?? '',
      role: primaryRole,
      roles: parsedRoles.isNotEmpty ? parsedRoles : [primaryRole],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'role': role,
      'roles': roles,
      'token': token,
    };
  }
}
