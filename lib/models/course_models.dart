class CourseModel {
  final String id;
  final String title;
  final String description;
  final String allocatedInstructorEmail;
  final List<SectionModel> sections;
  final List<String> pendingStudents;
  final List<String> enrolledStudents;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.allocatedInstructorEmail,
    List<SectionModel>? sections,
    List<String>? pendingStudents,
    List<String>? enrolledStudents,
  })  : sections = sections ?? [],
        pendingStudents = pendingStudents ?? [],
        enrolledStudents = enrolledStudents ?? [];

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      allocatedInstructorEmail: json['allocatedInstructorEmail']?.toString() ?? '',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => SectionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pendingStudents: (json['pendingStudents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      enrolledStudents: (json['enrolledStudents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'allocatedInstructorEmail': allocatedInstructorEmail,
      'sections': sections.map((e) => e.toJson()).toList(),
      'pendingStudents': pendingStudents,
      'enrolledStudents': enrolledStudents,
    };
  }
}

class SectionModel {
  final String id;
  final String title;
  final List<LessonModel> lessons;

  SectionModel({
    required this.id,
    required this.title,
    List<LessonModel>? lessons,
  }) : lessons = lessons ?? [];

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lessons': lessons.map((e) => e.toJson()).toList(),
    };
  }
}

class LessonModel {
  final String id;
  final String title;
  final String type; // 'Video', 'PDF', 'Text', 'Assignment'
  final String contentUrl; // Could be a link, or text content

  LessonModel({
    required this.id,
    required this.title,
    required this.type,
    required this.contentUrl,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Text',
      contentUrl: json['contentUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'contentUrl': contentUrl,
    };
  }
}

class AssignmentSubmissionModel {
  final String id;
  final String lessonId;
  final String studentEmail;
  final String fileName;
  final String filePath;
  final String submittedAt;

  AssignmentSubmissionModel({
    required this.id,
    required this.lessonId,
    required this.studentEmail,
    required this.fileName,
    required this.filePath,
    required this.submittedAt,
  });

  factory AssignmentSubmissionModel.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmissionModel(
      id: json['id']?.toString() ?? '',
      lessonId: json['lessonId']?.toString() ?? '',
      studentEmail: json['studentEmail']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      filePath: json['filePath']?.toString() ?? '',
      submittedAt: json['submittedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'studentEmail': studentEmail,
      'fileName': fileName,
      'filePath': filePath,
      'submittedAt': submittedAt,
    };
  }
}
