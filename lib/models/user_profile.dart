import 'dart:convert';

class CompleteProfile {
  final UserModel user;
  final ProfileModel profile;

  CompleteProfile({
    required this.user,
    required this.profile,
  });

  factory CompleteProfile.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return CompleteProfile(
      user: UserModel.fromJson(data['user'] ?? {}),
      profile: ProfileModel.fromJson(data['profile'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'profile': profile.toJson(),
    };
  }

  static CompleteProfile fromJsonString(String jsonString) {
    return CompleteProfile.fromJson(jsonDecode(jsonString));
  }

  String toJsonString() => jsonEncode(toJson());
}

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String password;
  final String role; // "STUDENT" or "INSTRUCTOR" or "Admin"
  final String status;
  final bool emailVerified;
  final String? profileImageUrl;
  final String? bio;
  final String? lastLoginAt;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    this.password = '',
    required this.role,
    this.status = 'ACTIVE',
    this.emailVerified = true,
    this.profileImageUrl,
    this.bio,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final fName = json['firstName']?.toString() ?? '';
    final lName = json['lastName']?.toString() ?? '';
    return UserModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: fName,
      lastName: lName,
      fullName: json['fullName']?.toString() ?? '$fName $lName'.trim(),
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      role: json['role']?.toString().toUpperCase() ?? 'STUDENT',
      status: json['status']?.toString() ?? 'ACTIVE',
      emailVerified: json['emailVerified'] ?? true,
      profileImageUrl: json['profileImageUrl']?.toString(),
      bio: json['bio']?.toString(),
      lastLoginAt: json['lastLoginAt']?.toString() ?? DateTime.now().toIso8601String(),
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role,
      'status': status,
      'emailVerified': emailVerified,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'lastLoginAt': lastLoginAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class ProfileModel {
  final String id;
  final String userId;

  // Student specific
  final String? dateOfBirth; // e.g. "2002-05-15"
  final String? educationLevel; // e.g. "Undergraduate"
  final List<String> learningGoals; // e.g. ["Learn Flutter"]

  // Instructor specific
  final String? headline; // e.g. "Senior Flutter Instructor"
  final String? qualification; // e.g. "BSc in Software Engineering"
  final int? experienceYears; // e.g. 5
  final List<String> expertise; // e.g. ["Flutter", "Dart"]
  final String? biography; // e.g. "Mobile application developer..."

  final String? createdAt;
  final String? updatedAt;

  ProfileModel({
    required this.id,
    required this.userId,
    this.dateOfBirth,
    this.educationLevel,
    this.learningGoals = const [],
    this.headline,
    this.qualification,
    this.experienceYears,
    this.expertise = const [],
    this.biography,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic item) {
      if (item is List) {
        return item.map((e) => e.toString()).toList();
      }
      return [];
    }

    return ProfileModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: json['userId']?.toString() ?? '',
      dateOfBirth: json['dateOfBirth']?.toString(),
      educationLevel: json['educationLevel']?.toString(),
      learningGoals: parseList(json['learningGoals']),
      headline: json['headline']?.toString(),
      qualification: json['qualification']?.toString(),
      experienceYears: json['experienceYears'] != null
          ? int.tryParse(json['experienceYears'].toString()) ?? 0
          : null,
      expertise: parseList(json['expertise']),
      biography: json['biography']?.toString(),
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (educationLevel != null) 'educationLevel': educationLevel,
      'learningGoals': learningGoals,
      if (headline != null) 'headline': headline,
      if (qualification != null) 'qualification': qualification,
      if (experienceYears != null) 'experienceYears': experienceYears,
      'expertise': expertise,
      if (biography != null) 'biography': biography,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
