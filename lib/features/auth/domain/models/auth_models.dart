class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatar;
  final String? role;
  final int? points;
  final DateTime? lastSeen;
  final int? totalActiveTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatar,
    this.role,
    this.points,
    this.lastSeen,
    this.totalActiveTime,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'] as String? ?? '', // Handle optional email from UserResource
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      role: json['role'] as String?,
      points: json['points'] as int?,
      lastSeen: json['last_seen'] != null 
          ? DateTime.parse(json['last_seen'] as String) 
          : null,
      totalActiveTime: json['total_active_time'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? email.split('@')[0];
  }

  /// Returns true if this user is a guest account
  bool get isGuest => email.startsWith('guest_') && email.endsWith('@guest.elbiblio.com');
}

class SignUpData {
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatar;
  final String? primaryLanguage;

  const SignUpData({
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatar,
    this.primaryLanguage,
  });
}

class AuthResponse {
  final User user;
  final String token;

  const AuthResponse({
    required this.user,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }
}

class AuthState {
  final bool isLoading;
  final bool isInitialized;
  final bool isGuest;
  final bool isAuthenticated;
  final User? user;
  final String? token;
  final String? error;
  final bool authRequired;
  final String? pendingAuthEmail;

  const AuthState({
    this.isLoading = false,
    this.isInitialized = false,
    this.isGuest = false,
    this.isAuthenticated = false,
    this.user,
    this.token,
    this.error,
    this.authRequired = false,
    this.pendingAuthEmail,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isInitialized,
    bool? isGuest,
    bool? isAuthenticated,
    User? user,
    String? token,
    String? error,
    bool? authRequired,
    String? pendingAuthEmail,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      isGuest: isGuest ?? this.isGuest,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      token: token ?? this.token,
      error: error ?? this.error,
      authRequired: authRequired ?? this.authRequired,
      pendingAuthEmail: pendingAuthEmail ?? this.pendingAuthEmail,
    );
  }
}
