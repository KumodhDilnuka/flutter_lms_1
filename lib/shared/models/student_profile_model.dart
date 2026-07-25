class StudentProfileModel {
  final String? educationLevel;
  final String? major;
  final String? graduationYear;
  final List<String> interests;
  final Map<String, dynamic> rawData;

  StudentProfileModel({
    this.educationLevel,
    this.major,
    this.graduationYear,
    this.interests = const [],
    this.rawData = const {},
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      educationLevel: json['educationLevel'] as String?,
      major: json['major'] as String?,
      graduationYear: json['graduationYear']?.toString(),
      interests: (json['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'educationLevel': educationLevel,
      'major': major,
      'graduationYear': graduationYear,
      'interests': interests,
    };
  }
}
