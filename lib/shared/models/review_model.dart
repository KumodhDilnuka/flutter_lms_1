class ReviewModel {
  final String id;
  final String courseId;
  final String studentId;
  final String studentName;
  final int rating;
  final String comment;
  final bool isHidden;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.studentName,
    required this.rating,
    required this.comment,
    this.isHidden = false,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    String parseStudentId(dynamic val) {
      if (val == null) return '';
      if (val is String) return val;
      if (val is Map) return val['id']?.toString() ?? val['_id']?.toString() ?? '';
      return val.toString();
    }

    String parseStudentName(dynamic val, Map<String, dynamic> fullJson) {
      if (val != null && val is String) return val;
      final st = fullJson['studentId'] ?? fullJson['student'];
      if (st != null && st is Map) {
        final f = st['firstName'] ?? '';
        final l = st['lastName'] ?? '';
        final name = '$f $l'.trim();
        if (name.isNotEmpty) return name;
      }
      return 'Anonymous Student';
    }

    return ReviewModel(
      id: json['id'] ?? json['_id'] ?? '',
      courseId: json['courseId'] ?? json['course'] ?? '',
      studentId: parseStudentId(json['studentId'] ?? json['student']),
      studentName: parseStudentName(json['studentName'], json),
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] ?? '',
      isHidden: json.containsKey('isVisible') ? !json['isVisible'] : (json['isHidden'] ?? false),
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now() 
          : DateTime.now(),
    );
  }
}
