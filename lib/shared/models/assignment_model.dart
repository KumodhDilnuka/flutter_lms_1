class AssignmentModel {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String? attachmentUrl;
  final bool isPublished;
  final DateTime? dueDate;

  AssignmentModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    this.attachmentUrl,
    required this.isPublished,
    this.dueDate,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] ?? json['_id'] ?? '',
      courseId: json['courseId'] ?? json['course'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      attachmentUrl: json['attachmentUrl'],
      isPublished: json['isPublished'] ?? false,
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
    );
  }
}

class AssignmentSubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String fileUrl;
  final int? grade;
  final String status;
  final DateTime submittedAt;

  AssignmentSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.fileUrl,
    this.grade,
    required this.status,
    required this.submittedAt,
  });

  factory AssignmentSubmissionModel.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmissionModel(
      id: json['id'] ?? json['_id'] ?? '',
      assignmentId: json['assignmentId'] ?? json['assignment'] ?? '',
      studentId: json['studentId'] ?? json['student'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      grade: json['grade'],
      status: json['status'] ?? 'SUBMITTED',
      submittedAt: json['submittedAt'] != null 
          ? DateTime.tryParse(json['submittedAt']) ?? DateTime.now() 
          : DateTime.now(),
    );
  }
}
