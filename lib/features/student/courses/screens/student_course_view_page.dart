import 'package:flutter/material.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/features/student/assignments/screens/assignment_submission_page.dart';

class StudentCourseViewPage extends StatelessWidget {
  final CourseModel course;
  final String studentEmail;

  const StudentCourseViewPage({super.key, required this.course, required this.studentEmail});

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Video': return Icons.play_circle_fill_rounded;
      case 'PDF': return Icons.picture_as_pdf_rounded;
      case 'Assignment': return Icons.assignment_rounded;
      default: return Icons.article_rounded;
    }
  }

  void _handleLessonTap(BuildContext context, LessonModel lesson) {
    if (lesson.type == 'Assignment') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AssignmentSubmissionPage(lesson: lesson, studentEmail: studentEmail),
        ),
      );
    } else {
      // Just show a simple dialog for reading/watching
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(lesson.title),
          content: Text('Simulating playing/viewing ${lesson.type}:\n\n${lesson.contentUrl}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(course.title)),
      body: course.sections.isEmpty
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
              itemCount: course.sections.length,
              itemBuilder: (context, index) {
                final section = course.sections[index];
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
                            leading: Icon(_getIconForType(lesson.type), color: Theme.of(context).colorScheme.primary),
                            title: Text(lesson.title),
                            subtitle: Text(lesson.type),
                            trailing: lesson.type == 'Assignment'
                                ? const Text('Submit', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
                                : const Icon(Icons.arrow_forward_ios, size: 14),
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
