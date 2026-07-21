import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_lms/shared/models/course_model.dart';

class AssignmentSubmissionPage extends StatefulWidget {
  final LessonModel lesson;
  final String studentEmail;

  const AssignmentSubmissionPage({super.key, required this.lesson, required this.studentEmail});

  @override
  State<AssignmentSubmissionPage> createState() => _AssignmentSubmissionPageState();
}

class _AssignmentSubmissionPageState extends State<AssignmentSubmissionPage> {
  String? _selectedFileName;
  String? _selectedFilePath;
  bool _isSubmitting = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'zip'],
    );
    
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFileName = result.files.first.name;
        _selectedFilePath = result.files.first.path;
      });
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file first')));
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final subsJson = prefs.getString('submissions') ?? '[]';
    final List<dynamic> currentSubs = jsonDecode(subsJson);

    final submission = AssignmentSubmissionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      lessonId: widget.lesson.id,
      studentEmail: widget.studentEmail,
      fileName: _selectedFileName!,
      filePath: _selectedFilePath ?? 'Web Upload (Path not available)',
      submittedAt: DateTime.now().toIso8601String(),
    );

    currentSubs.add(submission.toJson());
    await prefs.setString('submissions', jsonEncode(currentSubs));

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment Submitted Successfully!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Assignment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.lesson.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Instructions:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              widget.lesson.contentUrl.isEmpty ? 'No specific instructions provided.' : widget.lesson.contentUrl,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 40),

            // Upload Area
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2, style: BorderStyle.solid), // Dashed borders need custom painter, solid for simplicity
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFileName == null ? Icons.cloud_upload_outlined : Icons.insert_drive_file_rounded,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedFileName ?? 'Tap to select file (PDF, DOCX, ZIP)',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            if (_selectedFileName != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedFileName = null),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Remove File', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting || _selectedFileName == null ? null : _submitAssignment,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Assignment', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
