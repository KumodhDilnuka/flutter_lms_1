import 'package:flutter/material.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:url_launcher/url_launcher.dart';

class LessonViewerPage extends StatelessWidget {
  final LessonModel lesson;

  const LessonViewerPage({super.key, required this.lesson});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lesson.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(lesson.description, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            const SizedBox(height: 24),
            
            _buildLessonContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonContent(BuildContext context) {
    switch (lesson.lessonType) {
      case 'TEXT':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          width: double.infinity,
          child: Text(
            lesson.textContent ?? 'No content provided.',
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
            if (lesson.videoUrl != null)
              ElevatedButton.icon(
                onPressed: () => _launchUrl(context, lesson.videoUrl!),
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
            if (lesson.documentUrl != null)
              ElevatedButton.icon(
                onPressed: () => _launchUrl(context, lesson.documentUrl!),
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
