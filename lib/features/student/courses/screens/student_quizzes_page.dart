import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/shared/providers/course_provider.dart';
import 'package:flutter_lms/shared/models/quiz_model.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/features/student/courses/screens/quiz_taker_page.dart';

class StudentQuizzesPage extends StatefulWidget {
  final CourseModel course;

  const StudentQuizzesPage({super.key, required this.course});

  @override
  State<StudentQuizzesPage> createState() => _StudentQuizzesPageState();
}

class _StudentQuizzesPageState extends State<StudentQuizzesPage> {
  bool _isLoading = false;
  List<QuizModel> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  Future<void> _fetchQuizzes() async {
    setState(() => _isLoading = true);
    final provider = context.read<CourseProvider>();
    final fetched = await provider.fetchCourseQuizzes(widget.course.id);
    if (mounted) {
      setState(() {
        _quizzes = fetched;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.course.title} - Quizzes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
              ? const Center(child: Text('No quizzes available for this course.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = _quizzes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.quiz, color: Colors.blue),
                        title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(quiz.description ?? ''),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => QuizTakerPage(quizId: quiz.id)),
                            );
                          },
                          child: const Text('Take Quiz'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
