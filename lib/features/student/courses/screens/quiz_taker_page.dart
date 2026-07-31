import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/shared/providers/course_provider.dart';
import 'package:flutter_lms/shared/providers/notification_provider.dart';
import 'package:flutter_lms/shared/models/quiz_model.dart';

class QuizTakerPage extends StatefulWidget {
  final String quizId;

  const QuizTakerPage({super.key, required this.quizId});

  @override
  State<QuizTakerPage> createState() => _QuizTakerPageState();
}

class _QuizTakerPageState extends State<QuizTakerPage> {
  bool _isLoading = true;
  QuizModel? _quiz;
  QuizAttemptModel? _attempt;
  final Map<String, int> _selectedAnswers = {}; // Map of questionId to selected option index

  @override
  void initState() {
    super.initState();
    _fetchQuiz();
  }

  Future<void> _fetchQuiz() async {
    final provider = context.read<CourseProvider>();
    final quiz = await provider.getStudentQuiz(widget.quizId);
    
    // Also fetch past attempts to see if already taken
    final attempts = await provider.fetchMyAttempts(widget.quizId);
    if (attempts.isNotEmpty) {
      _attempt = attempts.first; // Just take the latest/first attempt
    }

    if (mounted) {
      setState(() {
        _quiz = quiz;
        _isLoading = false;
      });
    }
  }

  Future<void> _startAttempt() async {
    setState(() => _isLoading = true);
    final provider = context.read<CourseProvider>();
    final attempt = await provider.startQuizAttempt(widget.quizId);
    if (mounted) {
      setState(() {
        _attempt = attempt;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAttempt() async {
    if (_quiz == null || _attempt == null) return;
    
    // Build array of answers matching backend schema
    List<Map<String, dynamic>> answers = [];
    for (var q in _quiz!.questions) {
      final selectedOptIndex = _selectedAnswers[q.id];
      if (selectedOptIndex != null && selectedOptIndex < q.options.length) {
        answers.add({
          'questionId': q.id,
          'selectedOptionIds': [q.options[selectedOptIndex]['id']],
        });
      }
    }

    setState(() => _isLoading = true);
    final provider = context.read<CourseProvider>();
    final submitted = await provider.submitQuizAttempt(_attempt!.id, {'answers': answers});
    
    if (mounted) {
      setState(() {
        _attempt = submitted;
        _isLoading = false;
      });
      // Refresh notifications so the QUIZ_RESULT notification appears instantly
      context.read<NotificationProvider>().fetchNotifications();
      // Reload course progress to reflect the newly completed quiz
      await context.read<CourseProvider>().loadCourseProgress(_quiz!.courseId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz Submitted!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_quiz == null) {
      return const Scaffold(body: Center(child: Text('Quiz not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz!.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_quiz!.description ?? 'No description', style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 24),
            
            if (_attempt == null) ...[
              const Center(child: Text('Ready to test your knowledge?', style: TextStyle(fontSize: 20))),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startAttempt,
                child: const Text('Start Quiz'),
              )
            ] else if (_attempt!.status == 'SUBMITTED' || _attempt!.status == 'COMPLETED') ...[
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 64),
                    const SizedBox(height: 16),
                    const Text('Quiz Completed!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Your Score: ${_attempt!.score}', style: const TextStyle(fontSize: 20)),
                  ],
                ),
              )
            ] else ...[
              // Taking Quiz
              Expanded(
                child: ListView.builder(
                  itemCount: _quiz!.questions.length,
                  itemBuilder: (context, index) {
                    final question = _quiz!.questions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${index + 1}. ${question.text}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...List.generate(question.options.length, (optIndex) {
                              return RadioListTile<int>(
                                title: Text(question.options[optIndex]['text'] ?? ''),
                                value: optIndex,
                                groupValue: _selectedAnswers[question.id],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedAnswers[question.id] = val!;
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitAttempt,
                child: const Text('Submit Quiz'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
