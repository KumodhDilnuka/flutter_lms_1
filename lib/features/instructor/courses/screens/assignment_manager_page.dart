import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_lms/features/instructor/providers/instructor_provider.dart';
import 'package:flutter_lms/shared/models/assignment_model.dart';
import 'package:flutter_lms/shared/models/course_model.dart';

class AssignmentManagerPage extends StatefulWidget {
  final CourseModel course;

  const AssignmentManagerPage({super.key, required this.course});

  @override
  State<AssignmentManagerPage> createState() => _AssignmentManagerPageState();
}

class _AssignmentManagerPageState extends State<AssignmentManagerPage> {
  bool _isLoading = false;
  List<AssignmentModel> _assignments = [];

  @override
  void initState() {
    super.initState();
    _refreshAssignments();
  }

  Future<void> _refreshAssignments() async {
    setState(() => _isLoading = true);
    final provider = context.read<InstructorProvider>();
    final fetched = await provider.fetchInstructorAssignments(widget.course.id);
    if (mounted) {
      setState(() {
        _assignments = fetched;
        _isLoading = false;
      });
      if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load Error: ${provider.errorMessage}')));
      }
    }
  }

  void _showAddAssignmentDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final instructionsCtrl = TextEditingController();
    final maxMarksCtrl = TextEditingController(text: '100');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: instructionsCtrl, decoration: const InputDecoration(labelText: 'Instructions')),
                TextField(controller: maxMarksCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Maximum Marks')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final desc = descCtrl.text.trim();
                final instructions = instructionsCtrl.text.trim();
                final maxMarks = int.tryParse(maxMarksCtrl.text.trim()) ?? 100;
                
                if (title.length < 5 || desc.length < 5) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and description must be at least 5 characters long')));
                  return;
                }
                
                final provider = context.read<InstructorProvider>();
                
                String? sectionId;
                if (widget.course.sections.isNotEmpty) {
                  sectionId = widget.course.sections.first.id;
                }

                final payload = {
                  'title': title,
                  'description': desc,
                  'instructions': instructions.isEmpty ? desc : instructions,
                  'maximumMarks': maxMarks,
                  if (sectionId != null) 'sectionId': sectionId,
                };
                final res = await provider.createAssignment(widget.course.id, payload);
                if (!mounted) return;
                if (res != null) {
                  Navigator.pop(context);
                  _refreshAssignments();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment created!')));
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

  Future<void> _uploadAttachment(AssignmentModel assignment) async {
    FilePickerResult? result = await FilePicker.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      if (!mounted) return;
      final provider = context.read<InstructorProvider>();
      final res = await provider.uploadAssignmentAttachment(assignment.id, file);
      if (res != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attachment uploaded')));
        _refreshAssignments();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Upload failed')));
      }
    }
  }

  Future<void> _deleteAttachment(AssignmentModel assignment) async {
    final provider = context.read<InstructorProvider>();
    final success = await provider.deleteAttachment(assignment.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attachment removed')));
      _refreshAssignments();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Remove failed')));
    }
  }

  Future<void> _publishAssignment(AssignmentModel assignment) async {
    final provider = context.read<InstructorProvider>();
    final success = await provider.publishAssignment(assignment.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment published')));
      _refreshAssignments();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Publish failed')));
    }
  }
  
  Future<void> _deleteAssignment(AssignmentModel assignment) async {
    final provider = context.read<InstructorProvider>();
    final success = await provider.deleteAssignment(assignment.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment deleted')));
      _refreshAssignments();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Delete failed')));
    }
  }

  void _showSubmissionsDialog(AssignmentModel assignment) async {
    setState(() => _isLoading = true);
    final provider = context.read<InstructorProvider>();
    final submissions = await provider.fetchInstructorSubmissions(assignment.id);
    setState(() => _isLoading = false);
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Submissions'),
          content: SizedBox(
            width: double.maxFinite,
            child: submissions.isEmpty
                ? const Text('No submissions yet.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: submissions.length,
                    itemBuilder: (context, index) {
                      final sub = submissions[index];
                      return ListTile(
                        title: Text(sub.studentId),
                        subtitle: Text('Status: ${sub.status} | Grade: ${sub.grade ?? "None"}'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            // Quick grading dialog
                            final gradeCtrl = TextEditingController();
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Grade Submission'),
                                content: TextField(
                                  controller: gradeCtrl,
                                  decoration: const InputDecoration(labelText: 'Grade (0-100)'),
                                  keyboardType: TextInputType.number,
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final grade = int.tryParse(gradeCtrl.text);
                                      if (grade != null) {
                                        await provider.gradeSubmission(sub.id, {'grade': grade});
                                        Navigator.pop(ctx);
                                        Navigator.pop(context); // close submissions
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Graded!')));
                                      }
                                    },
                                    child: const Text('Save'),
                                  )
                                ],
                              )
                            );
                          },
                          child: const Text('Grade'),
                        ),
                      );
                    },
                  ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Assignments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddAssignmentDialog,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
              ? const Center(child: Text('No assignments yet. Add one!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = _assignments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(assignment.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                                if (!assignment.isPublished)
                                  IconButton(
                                    icon: const Icon(Icons.publish, color: Colors.blue),
                                    onPressed: () => _publishAssignment(assignment),
                                    tooltip: 'Publish',
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteAssignment(assignment),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                            Text('${assignment.description}\n${assignment.isPublished ? "PUBLISHED" : "DRAFT"}', style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _uploadAttachment(assignment),
                                      icon: const Icon(Icons.upload_file),
                                      label: const Text('Attachment'),
                                    ),
                                    if (assignment.attachmentUrl != null) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.link_off, color: Colors.orange),
                                        onPressed: () => _deleteAttachment(assignment),
                                      ),
                                    ]
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () => _showSubmissionsDialog(assignment),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  child: const Text('Submissions'),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
