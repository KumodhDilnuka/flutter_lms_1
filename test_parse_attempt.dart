import 'package:flutter_lms/shared/models/quiz_model.dart';
import 'dart:convert';

void main() async {
  final jsonStr = '''
  {
      "attempt": {
        "id": "1",
        "quizId": "1",
        "studentId": "1",
        "score": 0,
        "status": "IN_PROGRESS",
        "answers": [
          {
            "questionId": "q1",
            "selectedOptionIds": ["opt1"],
            "isCorrect": false,
            "pointsEarned": 0
          }
        ]
      }
  }
  ''';
  try {
    final data = jsonDecode(jsonStr);
    final q = QuizAttemptModel.fromJson(data['attempt']);
    print("Parsed correctly: \${q.id}, answers: \${q.answers.length}");
  } catch (e, stack) {
    print("Parse error: \$e");
    print(stack);
  }
}
