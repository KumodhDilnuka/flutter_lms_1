import 'package:flutter_lms/shared/models/review_model.dart';
import 'dart:convert';

void main() async {
  final jsonStr = '''
  {
      "review": {
        "id": "1",
        "courseId": "1",
        "studentId": {
          "_id": "s1",
          "firstName": "John",
          "lastName": "Doe"
        },
        "rating": 5,
        "comment": "Great course!",
        "isVisible": true
      }
  }
  ''';
  try {
    final data = jsonDecode(jsonStr);
    final r = ReviewModel.fromJson(data['review']);
    print("Parsed correctly: \${r.id}, studentName: \${r.studentName}");
  } catch (e, stack) {
    print("Parse error: \$e");
    print(stack);
  }
}
