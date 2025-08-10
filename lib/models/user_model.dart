class User {
  final String id;
  final String email;
  final String role;
  final String? name;
  final String? profileImage;

  const User({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      name: json['name'],
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
      'profileImage': profileImage,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.role == role &&
        other.name == name &&
        other.profileImage == profileImage;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        role.hashCode ^
        name.hashCode ^
        profileImage.hashCode;
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, role: $role, name: $name, profileImage: $profileImage)';
  }
}

class LoginRequest {
  final String email;
  final String password;
  final String role;

  LoginRequest({
    required this.email,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'role': role,
    };
  }
}

class LoginResponse {
  final User user;
  final String token;
  final bool success;
  final String? message;

  LoginResponse({
    required this.user,
    required this.token,
    required this.success,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Handle encrypted response format
    if (json['encrypted'] == true && json['data'] != null) {
      final data = json['data'];
      return LoginResponse(
        user: User.fromJson(data['user'] ?? {}),
        token: data['token'] ?? '',
        success: true,
        message: 'Login successful',
      );
    }
    
    // Handle regular response format
    return LoginResponse(
      user: User.fromJson(json['user'] ?? {}),
      token: json['token'] ?? '',
      success: json['success'] ?? false,
      message: json['message'],
    );
  }
}
