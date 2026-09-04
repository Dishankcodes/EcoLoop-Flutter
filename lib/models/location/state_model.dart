class StateModel {
  final int stateId;
  final String stateCode;
  final String stateName;

  StateModel({
    required this.stateId,
    required this.stateCode,
    required this.stateName,
  });

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      stateId: json['stateId'] is int
          ? json['stateId']
          : int.tryParse(json['stateId'].toString()) ?? 0,
      stateCode: json['stateCode']?.toString() ?? '',
      stateName: json['stateName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'stateId': stateId, 'stateCode': stateCode, 'stateName': stateName};
  }
}
