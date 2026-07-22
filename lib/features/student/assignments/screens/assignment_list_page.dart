import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/shared/providers/course_provider.dart';
import 'package:flutter_lms/shared/widgets/app_card.dart';
import 'package:flutter_lms/features/student/assignments/screens/assignment_submission_page.dart';

class AssignmentListPage extends StatefulWidget {
  final String studentEmail;

  const AssignmentListPage({super.key, required this.studentEmail});

  @override
  State<AssignmentListPage> createState() => _AssignmentListPageState();
}

class _AssignmentListPageState extends State<AssignmentListPage> {
  List<_AssignmentItem> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);

    final provider = context.read<CourseProvider>();
    final courses = provider.courses;

    // Load submissions from local storage
    final prefs = await SharedPreferences.getInstance();
    final subsJson = prefs.getString('submissions') ?? '[]';
    final List<dynamic> submissions = jsonDecode(subsJson);

    final Set<String> submittedLessonIds = {};
    final Map<String, String> submittedDates = {};
    for (final sub in submissions) {
      if (sub['studentEmail'] == widget.studentEmail) {
        submittedLessonIds.add(sub['lessonId'] ?? '');
        submittedDates[sub['lessonId'] ?? ''] = sub['submittedAt'] ?? '';
      }
    }

    final List<_AssignmentItem> items = [];
    for (final course in courses) {
      for (final section in course.sections) {
        for (final lesson in section.lessons) {
          if (lesson.lessonType == 'Assignment') {
            items.add(_AssignmentItem(
              lesson: lesson,
              courseName: course.title,
              sectionName: section.title,
              isSubmitted: submittedLessonIds.contains(lesson.id),
              submittedAt: submittedDates[lesson.id],
            ));
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _assignments = items;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No assignments available yet.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Enroll in a course to see assignments.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssignments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _assignments.length,
        itemBuilder: (context, index) {
          final item = _assignments[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              onTap: item.isSubmitted
                  ? null
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignmentSubmissionPage(
                            lesson: item.lesson,
                            studentEmail: widget.studentEmail,
                          ),
                        ),
                      );
                      _loadAssignments(); // Refresh after returning
                    },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.assignment_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.lesson.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      // Animated status chip
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.symmetric(
                          horizontal: item.isSubmitted ? 12 : 10,
                          vertical: item.isSubmitted ? 6 : 5,
                        ),
                        decoration: BoxDecoration(
                          color: item.isSubmitted
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: item.isSubmitted
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.isSubmitted ? Icons.check_circle : Icons.schedule,
                              size: 14,
                              color: item.isSubmitted ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.isSubmitted ? 'Submitted' : 'Pending',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: item.isSubmitted ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.courseName} • ${item.sectionName}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  if (item.isSubmitted && item.submittedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Submitted: ${_formatDate(item.submittedAt)}',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                    ),
                  ],
                  if (!item.isSubmitted) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tap to submit →',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Internal data class for assignment list items.
class _AssignmentItem {
  final LessonModel lesson;
  final String courseName;
  final String sectionName;
  final bool isSubmitted;
  final String? submittedAt;

  _AssignmentItem({
    required this.lesson,
    required this.courseName,
    required this.sectionName,
    required this.isSubmitted,
    this.submittedAt,
  });
}
