class UserData {
  final String? token;
  final String? tokenType;
  final String? expiresAt;
  final String? role;
  final num? accountId;
  final Account? account;

  UserData({
    this.token,
    this.tokenType,
    this.expiresAt,
    this.role,
    this.accountId,
    this.account,
  });

  factory UserData.fromJson(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) {
      return UserData();
    }

    return UserData(
      token: json['token']?.toString(),
      tokenType: json['tokenType']?.toString(),
      expiresAt: json['expiresAt']?.toString(),
      role: json['role']?.toString(),
      accountId: json['accountId'] is num
          ? json['accountId'] as num
          : num.tryParse(json['accountId']?.toString() ?? ''),
      account: json['account'] is Map<String, dynamic>
          ? Account.fromJson(json['account'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'tokenType': tokenType,
      'expiresAt': expiresAt,
      'role': role,
      'accountId': accountId,
      'account': account?.toJson(),
    };
  }
}

// ============================================================================
// ACCOUNT
// ============================================================================

class Account {
  final num? userId;

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? gender;

  final String? city;
  final String? state;
  final String? stateCode;

  final String? profilePhotoUrl;

  final String? role;
  final String? status;

  final String? createdAt;
  final String? updatedAt;

  Account({
    this.userId,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.gender,
    this.city,
    this.state,
    this.stateCode,
    this.profilePhotoUrl,
    this.role,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Account.fromJson(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) {
      return Account();
    }

    return Account(
      userId: json['userId'] is num
          ? json['userId'] as num
          : num.tryParse(json['userId']?.toString() ?? ''),

      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',

      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      stateCode: json['stateCode']?.toString() ?? '',

      profilePhotoUrl: json['profilePhotoUrl']?.toString() ?? '',

      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',

      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,

      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'gender': gender,

      'city': city,
      'state': state,
      'stateCode': stateCode,

      'profilePhotoUrl': profilePhotoUrl,

      'role': role,
      'status': status,

      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

// ============================================================================
// LOGIN REQUEST
// ============================================================================

class LoginRequest {
  final String email;
  final String password;
  final String? role;

  LoginRequest({required this.email, required this.password, this.role});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (role != null) 'role': role,
    };
  }

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      role: json['role']?.toString(),
    );
  }
}

// ============================================================================
// REGISTER USER REQUEST
// ============================================================================

class RegisterUserRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String gender;

  final String city;
  final String state;
  final String stateCode;

  final String password;

  final String? profilePhotoBase64;
  final String? profilePhotoFileName;
  final String? profilePhotoMimeType;

  RegisterUserRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.gender,

    required this.city,
    required this.state,
    required this.stateCode,

    required this.password,

    this.profilePhotoBase64,
    this.profilePhotoFileName,
    this.profilePhotoMimeType,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'gender': gender,

      'city': city,
      'state': state,
      'stateCode': stateCode,

      'password': password,

      if (profilePhotoBase64 != null) 'profilePhotoBase64': profilePhotoBase64,

      if (profilePhotoFileName != null)
        'profilePhotoFileName': profilePhotoFileName,

      if (profilePhotoMimeType != null)
        'profilePhotoMimeType': profilePhotoMimeType,
    };
  }

  factory RegisterUserRequest.fromJson(Map<String, dynamic> json) {
    return RegisterUserRequest(
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',

      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      stateCode: json['stateCode']?.toString() ?? '',

      password: json['password']?.toString() ?? '',

      profilePhotoBase64: json['profilePhotoBase64']?.toString(),

      profilePhotoFileName: json['profilePhotoFileName']?.toString(),

      profilePhotoMimeType: json['profilePhotoMimeType']?.toString(),
    );
  }
}
