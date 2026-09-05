class ArtistData {
  ArtistData({
    num? artistId,
    String? userName,
    String? email,
    String? phone,
    String? city,
    String? state,
    String? stateCode,
    String? profilePhotoUrl,
    String? bio,
    String? skills,
    String? experience,
    String? certificationUrl,
    String? role,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    _artistId = artistId;
    _userName = userName;
    _email = email;
    _phone = phone;
    _city = city;
    _state = state;
    _stateCode = stateCode;
    _profilePhotoUrl = profilePhotoUrl;
    _bio = bio;
    _skills = skills;
    _experience = experience;
    _certificationUrl = certificationUrl;
    _role = role;
    _status = status;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
  }

  ArtistData.fromJson(dynamic json) {
    if (json == null) {
      return;
    }
    _artistId = _parseNum(json['artistId']);
    _userName = json['userName']?.toString();
    _email = json['email']?.toString();
    _phone = json['phone']?.toString();
    _city = json['city']?.toString();
    _state = json['state']?.toString();
    _stateCode = json['stateCode']?.toString();
    _profilePhotoUrl = json['profilePhotoUrl']?.toString();
    _bio = json['bio']?.toString();
    _skills = json['skills']?.toString();
    _experience = json['experience']?.toString();
    _certificationUrl = json['certificationUrl']?.toString();
    _role = json['role']?.toString();
    _status = json['status']?.toString();
    _createdAt = json['createdAt']?.toString();
    _updatedAt = json['updatedAt']?.toString();
  }

  // FIELDS

  num? _artistId;
  String? _userName;
  String? _email;
  String? _phone;
  String? _city;
  String? _state;
  String? _stateCode;
  String? _profilePhotoUrl;
  String? _bio;
  String? _skills;
  String? _experience;
  String? _certificationUrl;
  String? _role;
  String? _status;
  String? _createdAt;
  String? _updatedAt;

  // COPY WITH
  ArtistData copyWith({
    num? artistId,
    String? userName,
    String? email,
    String? phone,
    String? city,
    String? state,
    String? stateCode,
    String? profilePhotoUrl,
    String? bio,
    String? skills,
    String? experience,
    String? certificationUrl,
    String? role,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) => ArtistData(
    artistId: artistId ?? _artistId,
    userName: userName ?? _userName,
    email: email ?? _email,
    phone: phone ?? _phone,
    city: city ?? _city,
    state: state ?? _state,
    stateCode: stateCode ?? _stateCode,
    profilePhotoUrl: profilePhotoUrl ?? _profilePhotoUrl,
    bio: bio ?? _bio,
    skills: skills ?? _skills,
    experience: experience ?? _experience,
    certificationUrl: certificationUrl ?? _certificationUrl,
    role: role ?? _role,
    status: status ?? _status,
    createdAt: createdAt ?? _createdAt,
    updatedAt: updatedAt ?? _updatedAt,
  );

  // GETTERS
  num? get artistId => _artistId;

  String? get userName => _userName;

  String? get email => _email;

  String? get phone => _phone;

  String? get city => _city;

  String? get state => _state;

  String? get stateCode => _stateCode;

  String? get profilePhotoUrl => _profilePhotoUrl;

  String? get bio => _bio;

  String? get skills => _skills;

  String? get experience => _experience;

  String? get certificationUrl => _certificationUrl;

  String? get role => _role;

  String? get status => _status;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;

  // TO JSON

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    map['artistId'] = _artistId;
    map['userName'] = _userName;
    map['email'] = _email;
    map['phone'] = _phone;
    map['city'] = _city;
    map['state'] = _state;
    map['stateCode'] = _stateCode;
    map['profilePhotoUrl'] = _profilePhotoUrl;
    map['bio'] = _bio;
    map['skills'] = _skills;
    map['experience'] = _experience;
    map['certificationUrl'] = _certificationUrl;
    map['role'] = _role;
    map['status'] = _status;
    map['createdAt'] = _createdAt;
    map['updatedAt'] = _updatedAt;

    return map;
  }

  // SAFE NUMBER PARSER

  static num? _parseNum(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value;
    }

    return num.tryParse(value.toString());
  }
}
