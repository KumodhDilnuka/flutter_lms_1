import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/shared/models/assignment_model.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/shared/providers/course_provider.dart';
import 'package:flutter_lms/shared/widgets/app_card.dart';
import 'package:flutter_lms/features/student/assignments/screens/assignment_submission_page.dart';

class AssignmentListPage extends StatefulWidget {
  final CourseModel? course;

  const AssignmentListPage({super.key, this.course});

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
    await provider.fetchMyEnrollments(); // ensure we have enrollments
    
    final List<_AssignmentItem> items = [];
    
    if (widget.course != null) {
      // Fetch only for the provided course
      final assignments = await provider.fetchStudentAssignments(widget.course!.id);
      for (final assignment in assignments) {
        final submission = await provider.getMySubmission(assignment.id);
        items.add(_AssignmentItem(
          assignment: assignment,
          courseName: widget.course!.title,
          isSubmitted: submission != null,
          submittedAt: submission != null ? submission.submittedAt.toIso8601String() : null,
        ));
      }
    } else {
      // Fetch assignments for all enrolled courses
      for (final enrollment in provider.myEnrollments) {
        final course = enrollment['course'];
        if (course != null) {
          String courseId;
          String courseTitle = 'Course';
          
          if (course is String) {
            courseId = course;
          } else if (course is Map) {
            courseId = course['id'] ?? course['_id'] ?? '';
            courseTitle = course['title'] ?? 'Course';
          } else {
            continue; // unknown format
          }
          
          if (courseId.isEmpty) continue;
          
          final assignments = await provider.fetchStudentAssignments(courseId);
          
          for (final assignment in assignments) {
            // Check if submitted
            final submission = await provider.getMySubmission(assignment.id);
            
            items.add(_AssignmentItem(
              assignment: assignment,
              courseName: courseTitle,
              isSubmitted: submission != null,
              submittedAt: submission != null ? submission.submittedAt.toIso8601String() : null,
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
      if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load Error: ${provider.errorMessage}')));
      }
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
    Widget content;
    
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_assignments.isEmpty) {
      content = Center(
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
    } else {
      content = RefreshIndicator(
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
                  ? () async {
                      // Already submitted, could view it, but let's just go to submission page to show status
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignmentSubmissionPage(
                            assignment: item.assignment,
                          ),
                        ),
                      );
                      _loadAssignments();
                    }
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignmentSubmissionPage(
                            assignment: item.assignment,
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
                          item.assignment.title,
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
                    item.courseName,
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

    if (widget.course != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assignments')),
        body: content,
      );
    }
    
    return content;
  }
}

class _AssignmentItem {
  final AssignmentModel assignment;
  final String courseName;
  final bool isSubmitted;
  final String? submittedAt;

  _AssignmentItem({
    required this.assignment,
    required this.courseName,
    required this.isSubmitted,
    this.submittedAt,
  });
}
