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
      accountId: json['accountId'] as num?,
      account: json['account'] != null
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

class Account {
  final num? userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? gender;
  final String? address;
  final String? city;
  final String? state;
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
    this.address,
    this.city,
    this.state,
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
      userId: json['userId'] as num?,
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
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
      'address': address,
      'city': city,
      'state': state,
      'profilePhotoUrl': profilePhotoUrl,
      'role': role,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
