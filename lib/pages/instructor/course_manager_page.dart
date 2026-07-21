import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/course_models.dart';

class CourseManagerPage extends StatefulWidget {
  final CourseModel course;
  const CourseManagerPage({super.key, required this.course});

  @override
  State<CourseManagerPage> createState() => _CourseManagerPageState();
}

class _CourseManagerPageState extends State<CourseManagerPage> {
  late CourseModel _course;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
  }

  Future<void> _saveCourseUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getString('courses') ?? '[]';
    final List<dynamic> decodedList = jsonDecode(coursesJson);
    
    final allCourses = decodedList.map((e) => CourseModel.fromJson(e)).toList();
    final index = allCourses.indexWhere((c) => c.id == _course.id);
    
    if (index != -1) {
      allCourses[index] = _course;
      await prefs.setString('courses', jsonEncode(allCourses.map((e) => e.toJson()).toList()));
    }
  }

  void _showAddSectionDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Section'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: 'e.g. Module 1: Introduction'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  setState(() {
                    _course.sections.add(SectionModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                    ));
                  });
                  _saveCourseUpdates();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Section'),
            ),
          ],
        );
      },
    );
  }

  void _showAddLessonDialog(String sectionId) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedType = 'Video';
    final types = ['Video', 'PDF', 'Text', 'Assignment'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Lesson'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Lesson Title'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Lesson Type'),
                    items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      setDialogState(() { selectedType = val!; });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(
                      labelText: selectedType == 'Assignment' ? 'Assignment Instructions' : 'Content URL / Text',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    final newLesson = LessonModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      type: selectedType,
                      contentUrl: contentController.text.trim(),
                    );
                    
                    setState(() {
                      final section = _course.sections.firstWhere((s) => s.id == sectionId);
                      section.lessons.add(newLesson);
                    });
                    
                    _saveCourseUpdates();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Lesson'),
              ),
            ],
          );
        });
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Video': return Icons.play_circle_fill_rounded;
      case 'PDF': return Icons.picture_as_pdf_rounded;
      case 'Assignment': return Icons.assignment_rounded;
      default: return Icons.article_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_course.title)),
      body: _course.sections.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers_clear_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No sections added yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _course.sections.length,
              itemBuilder: (context, index) {
                final section = _course.sections[index];
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
                            trailing: const Icon(Icons.edit, size: 16),
                          );
                        }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddLessonDialog(section.id),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Lesson'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSectionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Section'),
      ),
    );
  }
}
