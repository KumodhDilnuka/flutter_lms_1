import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/shared/providers/course_provider.dart';
import 'package:flutter_lms/features/student/courses/screens/lesson_viewer_page.dart';
import 'package:flutter_lms/features/student/courses/screens/student_quizzes_page.dart';
import 'package:flutter_lms/features/student/assignments/screens/assignment_list_page.dart';

class StudentCourseViewPage extends StatefulWidget {
  final CourseModel course;
  final String studentEmail;

  const StudentCourseViewPage({super.key, required this.course, required this.studentEmail});

  @override
  State<StudentCourseViewPage> createState() => _StudentCourseViewPageState();
}

class _StudentCourseViewPageState extends State<StudentCourseViewPage> {
  late CourseModel _course;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final provider = context.read<CourseProvider>();
    final detailedCourse = await provider.getCourseDetails(_course.id);
    final sections = await provider.fetchSections(_course.id);
    
    if (detailedCourse != null && mounted) {
      detailedCourse.sections.clear();
      detailedCourse.sections.addAll(sections);
      
      for (var section in detailedCourse.sections) {
        final lessons = await provider.fetchLessons(section.id);
        section.lessons.clear();
        section.lessons.addAll(lessons);
      }
      
      setState(() {
        _course = detailedCourse;
      });
    }
    if (mounted) setState(() => _isLoading = false);
    
    if (provider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading details: ${provider.errorMessage}')));
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'VIDEO': return Icons.play_circle_fill;
      case 'DOCUMENT': return Icons.picture_as_pdf;
      case 'ASSIGNMENT': return Icons.assignment;
      default: return Icons.article;
    }
  }

  void _handleLessonTap(BuildContext context, LessonModel lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonViewerPage(lesson: lesson),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_course.title),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _course.sections.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers_clear_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No content available in this course yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _course.sections.length + 2, // +2 for Assignments and Quizzes pseudo-sections
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                    child: ListTile(
                      leading: Icon(Icons.assignment, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Course Assignments', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('View and submit assignments'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AssignmentListPage(course: _course)),
                        );
                      },
                    ),
                  );
                }
                if (index == 1) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 24), // Extra margin to separate from curriculum
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
                    child: ListTile(
                      leading: Icon(Icons.quiz, color: Theme.of(context).colorScheme.secondary),
                      title: const Text('Course Quizzes', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Take quizzes for this course'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => StudentQuizzesPage(course: _course)),
                        );
                      },
                    ),
                  );
                }

                final section = _course.sections[index - 2];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    children: [
                      if (section.lessons.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No lessons in this section.'),
                        )
                      else
                        ...section.lessons.map((lesson) {
                          return ListTile(
                            leading: Icon(_getIconForType(lesson.lessonType), color: Theme.of(context).colorScheme.primary),
                            title: Text(lesson.title),
                            subtitle: Text(lesson.lessonType),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () => _handleLessonTap(context, lesson),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
