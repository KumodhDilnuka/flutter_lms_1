import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_lms/shared/models/assignment_model.dart';
import 'package:flutter_lms/shared/providers/course_provider.dart';

class AssignmentSubmissionPage extends StatefulWidget {
  final AssignmentModel assignment;

  const AssignmentSubmissionPage({super.key, required this.assignment});

  @override
  State<AssignmentSubmissionPage> createState() => _AssignmentSubmissionPageState();
}

class _AssignmentSubmissionPageState extends State<AssignmentSubmissionPage> {
  String? _selectedFileName;
  String? _selectedFilePath;
  bool _isSubmitting = false;
  AssignmentSubmissionModel? _submission;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSubmission();
  }

  Future<void> _checkSubmission() async {
    final provider = context.read<CourseProvider>();
    final submission = await provider.getMySubmission(widget.assignment.id);
    if (mounted) {
      setState(() {
        _submission = submission;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'zip'],
    );
    
    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
      setState(() {
        _selectedFileName = result.files.first.name;
        _selectedFilePath = result.files.first.path;
      });
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file first')));
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<CourseProvider>();
    final file = File(_selectedFilePath!);
    
    AssignmentSubmissionModel? newSubmission;
    if (_submission != null) {
      // Replace existing
      newSubmission = await provider.replaceSubmissionFile(_submission!.id, file);
    } else {
      // Create new
      newSubmission = await provider.submitAssignment(widget.assignment.id, file);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    
    if (newSubmission != null) {
      setState(() => _submission = newSubmission);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment Submitted Successfully!')));
      Navigator.pop(context);
    } else {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Error'),
          content: Text(provider.errorMessage ?? 'Submission failed'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Assignment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.assignment.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Instructions:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(widget.assignment.description),
                  const SizedBox(height: 24),

                  if (widget.assignment.attachmentUrl != null) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        // In a real app, this would download or open the attachmentUrl
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening attachment...')));
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download Instructor Attachment'),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (_submission != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              Text('Submitted', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Grade: ${_submission!.grade != null ? _submission!.grade.toString() : "Pending"}'),
                          Text('File: ${_submission!.fileUrl.split("/").last}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Replace Submission:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                  ],

                  // Upload Area
                  GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _selectedFileName == null ? Icons.cloud_upload_outlined : Icons.insert_drive_file_rounded,
                            size: 48,
                            color: _selectedFileName == null ? Colors.blue : Colors.green,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFileName ?? 'Tap to select a file\n(PDF, DOC, DOCX, ZIP)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedFileName == null ? Colors.grey.shade600 : Colors.green.shade700,
                              fontWeight: _selectedFileName == null ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting || _selectedFileName == null ? null : _submitAssignment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_submission != null ? 'Replace File' : 'Submit Assignment', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
