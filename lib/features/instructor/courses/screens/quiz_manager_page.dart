import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/features/instructor/providers/instructor_provider.dart';
import 'package:flutter_lms/shared/models/quiz_model.dart';
import 'package:flutter_lms/shared/models/course_model.dart';

class QuizManagerPage extends StatefulWidget {
  final CourseModel course;

  const QuizManagerPage({super.key, required this.course});

  @override
  State<QuizManagerPage> createState() => _QuizManagerPageState();
}

class _QuizManagerPageState extends State<QuizManagerPage> {
  bool _isLoading = false;
  List<QuizModel> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _refreshQuizzes();
  }

  Future<void> _refreshQuizzes() async {
    setState(() => _isLoading = true);
    final provider = context.read<InstructorProvider>();
    final fetchedQuizzes = await provider.fetchInstructorQuizzes(widget.course.id);
    
    final detailedQuizzes = <QuizModel>[];
    for (var q in fetchedQuizzes) {
      final detailed = await provider.getInstructorQuiz(q.id);
      if (detailed != null) {
        detailedQuizzes.add(detailed);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load quiz details for \${q.title}: \${provider.errorMessage}')));
        }
        detailedQuizzes.add(q);
      }
    }
    
    if (mounted) {
      setState(() {
        _quizzes = detailedQuizzes;
        _isLoading = false;
      });
    }
  }

  void _showAddQuizDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final passingScoreCtrl = TextEditingController(text: '50');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Quiz'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              TextField(
                controller: passingScoreCtrl, 
                decoration: const InputDecoration(labelText: 'Passing Score (0-100)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                final provider = context.read<InstructorProvider>();
                final passingScore = int.tryParse(passingScoreCtrl.text) ?? 50;
                final payload = {
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'passingScore': passingScore,
                };
                final res = await provider.createQuiz(widget.course.id, payload);
                if (!mounted) return;
                if (res != null) {
                  Navigator.pop(context);
                  _refreshQuizzes();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz created successfully!')));
                } else {
                  showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Error'),
                      content: Text(provider.errorMessage ?? 'Failed'),
                      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
                    )
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      }
    );
  }

  void _showAddQuestionDialog(QuizModel quiz) {
    final textCtrl = TextEditingController();
    final opt1Ctrl = TextEditingController();
    final opt2Ctrl = TextEditingController();
    final opt3Ctrl = TextEditingController();
    final opt4Ctrl = TextEditingController();
    int correctIdx = 0;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: textCtrl, decoration: const InputDecoration(labelText: 'Question Text')),
                    const SizedBox(height: 16),
                    TextField(controller: opt1Ctrl, decoration: const InputDecoration(labelText: 'Option 1')),
                    TextField(controller: opt2Ctrl, decoration: const InputDecoration(labelText: 'Option 2')),
                    TextField(controller: opt3Ctrl, decoration: const InputDecoration(labelText: 'Option 3')),
                    TextField(controller: opt4Ctrl, decoration: const InputDecoration(labelText: 'Option 4')),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: correctIdx,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Option 1 is correct')),
                        DropdownMenuItem(value: 1, child: Text('Option 2 is correct')),
                        DropdownMenuItem(value: 2, child: Text('Option 3 is correct')),
                        DropdownMenuItem(value: 3, child: Text('Option 4 is correct')),
                      ],
                      onChanged: (v) => setDialogState(() => correctIdx = v!),
                      decoration: const InputDecoration(labelText: 'Correct Answer'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (textCtrl.text.isEmpty || opt1Ctrl.text.isEmpty || opt2Ctrl.text.isEmpty) return;
                    final provider = context.read<InstructorProvider>();
                    final options = <Map<String, String>>[];
                    options.add({'id': '0', 'text': opt1Ctrl.text});
                    options.add({'id': '1', 'text': opt2Ctrl.text});
                    if (opt3Ctrl.text.isNotEmpty) options.add({'id': '2', 'text': opt3Ctrl.text});
                    if (opt4Ctrl.text.isNotEmpty) options.add({'id': '3', 'text': opt4Ctrl.text});
                    
                    final payload = {
                      'questionText': textCtrl.text,
                      'questionType': 'SINGLE_CHOICE',
                      'options': options,
                      'correctOptionIds': [correctIdx.toString()],
                      'marks': 1,
                    };
                    
                    final res = await provider.createQuestion(quiz.id, payload);
                    if (!mounted) return;
                    if (res != null) {
                      Navigator.pop(context);
                      _refreshQuizzes();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question created!')));
                    } else {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Error'),
                          content: Text(provider.errorMessage ?? 'Failed'),
                          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
                        )
                      );
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _publishQuiz(QuizModel quiz) async {
    final provider = context.read<InstructorProvider>();
    final success = await provider.publishQuiz(quiz.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz published')));
      _refreshQuizzes();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Publish failed')));
    }
  }
  
  Future<void> _deleteQuiz(QuizModel quiz) async {
    final provider = context.read<InstructorProvider>();
    final success = await provider.deleteQuiz(quiz.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz deleted')));
      _refreshQuizzes();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Delete failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Quizzes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddQuizDialog,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
              ? const Center(child: Text('No quizzes yet. Add one!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = _quizzes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${quiz.description ?? ''}\n${quiz.isPublished ? "PUBLISHED" : "DRAFT"}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!quiz.isPublished)
                              IconButton(
                                icon: const Icon(Icons.publish, color: Colors.blue),
                                onPressed: () => _publishQuiz(quiz),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteQuiz(quiz),
                            ),
                          ],
                        ),
                        children: [
                          const Divider(),
                          if (quiz.questions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No questions added yet.'),
                            )
                          else
                            ...quiz.questions.map((q) => ListTile(
                              title: Text(q.text),
                              subtitle: Text('Options: ${q.options.length} | Points: ${q.points}'),
                            )),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextButton.icon(
                              onPressed: () => _showAddQuestionDialog(quiz),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Question'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
