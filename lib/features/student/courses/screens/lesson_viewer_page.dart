import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/shared/providers/course_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LessonViewerPage extends StatefulWidget {
  final LessonModel lesson;

  const LessonViewerPage({super.key, required this.lesson});

  @override
  State<LessonViewerPage> createState() => _LessonViewerPageState();
}

class _LessonViewerPageState extends State<LessonViewerPage> {
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _startLesson();
  }

  Future<void> _startLesson() async {
    // Fire and forget
    context.read<CourseProvider>().startLesson(widget.lesson.id);
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open file')));
      }
    }
  }

  Future<void> _markAsComplete() async {
    setState(() => _isCompleting = true);
    final success = await context.read<CourseProvider>().completeLesson(widget.lesson.id);
    
    if (mounted) {
      setState(() => _isCompleting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson completed!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.read<CourseProvider>().errorMessage ?? 'Failed to complete lesson')
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.lesson.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.lesson.description, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            const SizedBox(height: 24),
            
            _buildLessonContent(context),

            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Consumer<CourseProvider>(
                builder: (context, provider, child) {
                  final isAlreadyCompleted = provider.lessonProgressStatus[widget.lesson.id] == 'COMPLETED';
                  if (isAlreadyCompleted) {
                    return ElevatedButton.icon(
                      onPressed: null, // Disabled if already completed
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Lesson Completed'),
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: Colors.green.shade100,
                        disabledForegroundColor: Colors.green.shade700,
                      ),
                    );
                  }
                  
                  return ElevatedButton(
                    onPressed: _isCompleting ? null : _markAsComplete,
                    child: _isCompleting 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Mark as Complete', style: TextStyle(fontSize: 16)),
                  );
                }
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonContent(BuildContext context) {
    switch (widget.lesson.lessonType) {
      case 'TEXT':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          width: double.infinity,
          child: Text(
            widget.lesson.textContent ?? 'No content provided.',
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
        );
      case 'VIDEO':
        return Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (widget.lesson.videoUrl != null)
              ElevatedButton.icon(
                onPressed: () => _launchUrl(context, widget.lesson.videoUrl!),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open Video Externally'),
              )
            else
              const Text('Video file not available.'),
          ],
        );
      case 'DOCUMENT':
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.picture_as_pdf, size: 64, color: Colors.blue.shade400),
                  const SizedBox(height: 16),
                  const Text('Document Material', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.lesson.documentUrl != null)
              ElevatedButton.icon(
                onPressed: () => _launchUrl(context, widget.lesson.documentUrl!),
                icon: const Icon(Icons.download),
                label: const Text('Download / View Document'),
              )
            else
              const Text('Document file not available.'),
          ],
        );
      default:
        return const Text('Unsupported lesson format.');
    }
  }
}
