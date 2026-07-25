class QuizModel {
  final String id;
  final String title;
  final String? description;
  final bool isPublished;
  final String courseId;
  final List<QuestionModel> questions;

  QuizModel({
    required this.id,
    required this.title,
    this.description,
    required this.isPublished,
    required this.courseId,
    this.questions = const [],
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      isPublished: json['isPublished'] ?? false,
      courseId: json['courseId'] ?? json['course'] ?? '',
      questions: (json['questions'] as List?)
              ?.map((q) => QuestionModel.fromJson(q))
              .toList() ??
          [],
    );
  }
}

class QuestionModel {
  final String id;
  final String text; // mapped from questionText
  final String questionType;
  final List<Map<String, String>> options;
  final List<String> correctOptionIds;
  final num points; // mapped from marks

  QuestionModel({
    required this.id,
    required this.text,
    required this.questionType,
    required this.options,
    required this.correctOptionIds,
    required this.points,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] ?? json['_id'] ?? '',
      text: json['questionText'] ?? json['text'] ?? '',
      questionType: json['questionType'] ?? 'SINGLE_CHOICE',
      options: (json['options'] as List<dynamic>?)?.map((opt) {
        if (opt is String) return {'id': opt, 'text': opt}; // fallback for old data
        return {
          'id': (opt['id'] ?? '').toString(),
          'text': (opt['text'] ?? '').toString(),
        };
      }).toList() ?? [],
      correctOptionIds: json['correctOptionIds'] != null 
          ? List<String>.from(json['correctOptionIds']) 
          : (json['correctAnswer'] != null ? [json['correctAnswer'].toString()] : []), // fallback
      points: json['marks'] ?? json['points'] ?? 1,
    );
  }
}

class QuizAttemptModel {
  final String id;
  final String quizId;
  final String studentId;
  final int score;
  final String status;
  final List<Map<String, dynamic>> answers;

  QuizAttemptModel({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.score,
    required this.status,
    required this.answers,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      id: json['id'] ?? json['_id'] ?? '',
      quizId: json['quizId'] ?? json['quiz'] ?? '',
      studentId: json['studentId'] ?? json['student'] ?? '',
      score: json['score'] ?? 0,
      status: json['status'] ?? 'PENDING',
      answers: (json['answers'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
    );
  }
}
