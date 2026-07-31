class LessonProgressModel {
  final String lessonId;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;

  LessonProgressModel({
    required this.lessonId,
    required this.status,
    this.startedAt,
    this.completedAt,
  });

  factory LessonProgressModel.fromJson(Map<String, dynamic> json) {
    return LessonProgressModel(
      lessonId: json['lessonId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'NOT_STARTED',
      startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
    );
  }
}

class CourseProgressModel {
  final int progressPercentage;
  final String enrollmentStatus;
  final int totalLessons;
  final int completedLessons;
  final List<LessonProgressModel> lessons;

  CourseProgressModel({
    required this.progressPercentage,
    required this.enrollmentStatus,
    required this.totalLessons,
    required this.completedLessons,
    this.lessons = const [],
  });

  factory CourseProgressModel.fromJson(Map<String, dynamic> json) {
    // Handling different response structures depending on endpoint
    
    int progress = 0;
    String status = 'ACTIVE';
    int total = 0;
    int completed = 0;
    List<LessonProgressModel> lessonsList = [];

    // Structure from completeLesson
    if (json.containsKey('courseProgress')) {
      final progressData = json['courseProgress'];
      progress = progressData['progressPercentage'] ?? 0;
      status = progressData['enrollmentStatus'] ?? 'ACTIVE';
      total = progressData['totalLessons'] ?? 0;
      completed = progressData['completedLessons'] ?? 0;
    }
    // Structure from getMyCourseProgress / getEnrollmentProgress
    else if (json.containsKey('enrollment') || json.containsKey('progressPercentage')) {
      final enrollment = json['enrollment'] ?? {};
      num p = json['progressPercentage'] ?? enrollment['progressPercentage'] ?? enrollment['progress'] ?? 0;
      progress = p.toInt();
      status = enrollment['status'] ?? json['status'] ?? 'ACTIVE';
      
      if (json.containsKey('lessons')) {
        final lessonsData = json['lessons'] as List;
        total = lessonsData.length;
        
        for (var lesson in lessonsData) {
          if (lesson['progress'] != null) {
            final p = LessonProgressModel.fromJson({
              ...lesson['progress'],
              'lessonId': lesson['_id'] ?? lesson['id'],
            });
            lessonsList.add(p);
            if (p.status == 'COMPLETED') completed++;
          }
        }
      }
    }

    return CourseProgressModel(
      progressPercentage: progress,
      enrollmentStatus: status,
      totalLessons: total,
      completedLessons: completed,
      lessons: lessonsList,
    );
  }
}
