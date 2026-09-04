class CityModel {
  final int cityId;
  final String stateCode;
  final String cityName;

  CityModel({
    required this.cityId,
    required this.stateCode,
    required this.cityName,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      cityId: json['cityId'] is int
          ? json['cityId']
          : int.tryParse(json['cityId'].toString()) ?? 0,
      stateCode: json['stateCode']?.toString() ?? '',
      cityName: json['cityName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'cityId': cityId, 'stateCode': stateCode, 'cityName': cityName};
  }
}
