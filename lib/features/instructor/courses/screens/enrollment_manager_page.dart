import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/features/instructor/providers/instructor_provider.dart';
import 'package:flutter_lms/shared/models/course_model.dart';

class EnrollmentManagerPage extends StatefulWidget {
  final CourseModel course;
  const EnrollmentManagerPage({super.key, required this.course});

  @override
  State<EnrollmentManagerPage> createState() => _EnrollmentManagerPageState();
}

class _EnrollmentManagerPageState extends State<EnrollmentManagerPage> {
  List<Map<String, dynamic>> _enrollments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    setState(() => _isLoading = true);
    final provider = context.read<InstructorProvider>();
    final result = await provider.getCourseEnrollments(widget.course.id);
    if (mounted) {
      setState(() {
        _enrollments = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _approveEnrollment(String enrollmentId) async {
    final provider = context.read<InstructorProvider>();
    final success = await provider.approveEnrollment(enrollmentId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment approved!'), backgroundColor: Colors.green),
        );
        _loadEnrollments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Approval failed')),
        );
      }
    }
  }

  Future<void> _rejectEnrollment(String enrollmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Enrollment'),
        content: const Text('Are you sure you want to reject this enrollment request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final provider = context.read<InstructorProvider>();
    final success = await provider.rejectEnrollment(enrollmentId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment rejected'), backgroundColor: Colors.orange),
        );
        _loadEnrollments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Rejection failed')),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
      case 'ACTIVE':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'ACTIVE':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      case 'CANCELLED':
        return Icons.block;
      case 'PENDING':
      default:
        return Icons.hourglass_top;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrolled Students'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrollments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No enrolled students yet.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadEnrollments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _enrollments.length,
                    itemBuilder: (context, index) {
                      final enrollment = _enrollments[index];
                      final id = enrollment['_id']?.toString() ?? enrollment['id']?.toString() ?? '';
                      final status = (enrollment['status'] as String?) ?? 'PENDING';
                      final canAct = status.toUpperCase() == 'PENDING' || status.toUpperCase() == 'ACTIVE';

                      // Extract student info
                      var studentData = enrollment['student'] ?? enrollment['studentId'] ?? enrollment['user'];
                      final student = studentData is Map ? studentData as Map<String, dynamic> : null;
                      
                      String studentName = 'Unknown Student';
                      if (student != null) {
                        final fName = student['firstName']?.toString() ?? '';
                        final lName = student['lastName']?.toString() ?? '';
                        if (fName.isNotEmpty || lName.isNotEmpty) {
                          studentName = '$fName $lName'.trim();
                        } else if (student['name'] != null) {
                          studentName = student['name'].toString();
                        }
                      }
                      
                      final studentEmail = student?['email'] ?? enrollment['studentEmail'] ?? '';
                      final createdAt = enrollment['createdAt'] as String?;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _statusColor(status).withOpacity(0.15),
                                    child: Icon(Icons.person, color: _statusColor(status)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          studentName.toString(),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        if (studentEmail.toString().isNotEmpty)
                                          Text(
                                            studentEmail.toString(),
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    avatar: Icon(_statusIcon(status), size: 16, color: _statusColor(status)),
                                    label: Text(
                                      status,
                                      style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                    backgroundColor: _statusColor(status).withOpacity(0.1),
                                    side: BorderSide.none,
                                  ),
                                ],
                              ),
                              if (createdAt != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Enrolled: ${_formatDate(createdAt)}',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }
}
