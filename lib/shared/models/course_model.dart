class CourseModel {
  final String id;
  final String title;
  final String shortDescription;
  final String description;
  final String categoryId;
  final String allocatedInstructorEmail;
  final String level;
  final String language;
  final List<String> requirements;
  final List<String> learningOutcomes;
  final List<String> targetAudience;
  final String status;
  final String? thumbnailUrl;
  final double price;
  final List<SectionModel> sections;

  CourseModel({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.description,
    required this.categoryId,
    required this.allocatedInstructorEmail,
    required this.level,
    required this.language,
    this.requirements = const [],
    this.learningOutcomes = const [],
    this.targetAudience = const [],
    required this.status,
    this.thumbnailUrl,
    this.price = 0.0,
    this.sections = const [],
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      shortDescription: json['shortDescription']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? json['category']?['_id']?.toString() ?? '',
      allocatedInstructorEmail: json['instructor']?['email']?.toString() ?? json['allocatedInstructorEmail']?.toString() ?? (json['instructorId'] is Map ? '${json['instructorId']['firstName']} ${json['instructorId']['lastName']}' : ''),
      level: json['level']?.toString() ?? 'ALL_LEVELS',
      language: json['language']?.toString() ?? 'English',
      requirements: (json['requirements'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      learningOutcomes: (json['learningOutcomes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      targetAudience: (json['targetAudience'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      status: json['status']?.toString() ?? 'DRAFT',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      price: (json['price'] ?? 0.0).toDouble(),
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => SectionModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'shortDescription': shortDescription,
      'description': description,
      'categoryId': categoryId,
      'level': level,
      'language': language,
      'requirements': requirements,
      'learningOutcomes': learningOutcomes,
      'targetAudience': targetAudience,
      'status': status,
    };
  }
}

class SectionModel {
  final String id;
  final String title;
  final String description;
  final int order;
  final bool isPublished;
  final List<LessonModel> lessons;

  SectionModel({
    required this.id,
    required this.title,
    required this.description,
    this.order = 0,
    this.isPublished = false,
    this.lessons = const [],
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      order: json['order'] ?? 0,
      isPublished: json['isPublished'] ?? false,
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'order': order,
      'isPublished': isPublished,
    };
  }
}

class LessonModel {
  final String id;
  final String title;
  final String description;
  final String lessonType; // TEXT, VIDEO, DOCUMENT
  final String? textContent;
  final String? videoUrl;
  final String? documentUrl;
  final int durationMinutes;
  final bool isPreview;
  final bool isPublished;

  LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.lessonType,
    this.textContent,
    this.videoUrl,
    this.documentUrl,
    this.durationMinutes = 0,
    this.isPreview = false,
    this.isPublished = false,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      lessonType: json['lessonType']?.toString() ?? 'TEXT',
      textContent: json['textContent']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      documentUrl: json['documentUrl']?.toString(),
      durationMinutes: json['durationMinutes'] ?? 0,
      isPreview: json['isPreview'] ?? false,
      isPublished: json['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'lessonType': lessonType,
      'textContent': textContent,
      'durationMinutes': durationMinutes,
      'isPreview': isPreview,
      'isPublished': isPublished,
    };
  }
}


