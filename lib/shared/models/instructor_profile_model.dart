class InstructorProfileModel {
  final String? title;
  final String? department;
  final List<String> expertise;
  final String? yearsOfExperience;
  final Map<String, dynamic> rawData;

  InstructorProfileModel({
    this.title,
    this.department,
    this.expertise = const [],
    this.yearsOfExperience,
    this.rawData = const {},
  });

  factory InstructorProfileModel.fromJson(Map<String, dynamic> json) {
    return InstructorProfileModel(
      title: json['title'] as String?,
      department: json['department'] as String?,
      expertise: (json['expertise'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      yearsOfExperience: json['yearsOfExperience']?.toString(),
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'department': department,
      'expertise': expertise,
      'yearsOfExperience': yearsOfExperience,
    };
  }
}
