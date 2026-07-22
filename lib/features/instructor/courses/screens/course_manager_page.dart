import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_lms/features/instructor/providers/instructor_provider.dart';
import 'package:flutter_lms/shared/models/course_model.dart';

class CourseManagerPage extends StatefulWidget {
  final CourseModel course;

  const CourseManagerPage({super.key, required this.course});

  @override
  State<CourseManagerPage> createState() => _CourseManagerPageState();
}

class _CourseManagerPageState extends State<CourseManagerPage> {
  late CourseModel _course;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _refreshCourse();
  }

  Future<void> _refreshCourse() async {
    setState(() => _isLoading = true);
    final provider = context.read<InstructorProvider>();
    final updated = await provider.getCourseDetails(_course.id);
    final sections = await provider.fetchSections(_course.id);
    if (updated != null && mounted) {
      // Overwrite the sections array with the explicitly fetched sections since getCourseDetails might omit them
      updated.sections.clear();
      updated.sections.addAll(sections);
      
      // Also fetch lessons for each section since fetchSections might omit them
      for (var section in updated.sections) {
        final lessons = await provider.fetchLessons(section.id);
        section.lessons.clear();
        section.lessons.addAll(lessons);
      }
      
      setState(() {
        _course = updated;
      });
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _publishCourse() async {
    final provider = context.read<InstructorProvider>();
    final success = await provider.publishCourse(_course.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course Published!')));
      _refreshCourse();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to publish')));
    }
  }

  Future<void> _uploadThumbnail() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      if (!mounted) return;
      final provider = context.read<InstructorProvider>();
      final success = await provider.uploadThumbnail(_course.id, file);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thumbnail uploaded')));
        _refreshCourse();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Upload failed')));
      }
    }
  }

  void _showAddSectionDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Section'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                final provider = context.read<InstructorProvider>();
                final res = await provider.createSection(_course.id, titleCtrl.text, descCtrl.text, false);
                if (!mounted) return;
                if (res != null) {
                  Navigator.pop(context);
                  setState(() {
                    _course.sections.add(res);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Section created successfully!')));
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

  void _showAddLessonDialog(SectionModel section) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final contentCtrl = TextEditingController(); // For TEXT lessons
    String selectedType = 'TEXT';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Lesson'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      items: const [
                        DropdownMenuItem(value: 'TEXT', child: Text('Text')),
                        DropdownMenuItem(value: 'VIDEO', child: Text('Video')),
                        DropdownMenuItem(value: 'DOCUMENT', child: Text('Document')),
                      ],
                      onChanged: (v) => setDialogState(() => selectedType = v!),
                      decoration: const InputDecoration(labelText: 'Lesson Type'),
                    ),
                    if (selectedType == 'TEXT')
                      TextField(
                        controller: contentCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Text Content'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.isEmpty) return;
                    final provider = context.read<InstructorProvider>();
                    final payload = {
                      'title': titleCtrl.text,
                      'description': descCtrl.text,
                      'lessonType': selectedType,
                      if (selectedType == 'TEXT') 'textContent': contentCtrl.text,
                    };
                    
                    final res = await provider.createLesson(section.id, payload);
                    if (!mounted) return;
                    if (res != null) {
                      Navigator.pop(context);
                      setState(() {
                        section.lessons.add(res);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson created successfully!')));
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
    );
  }

  Future<void> _uploadLessonMedia(LessonModel lesson) async {
    FileType type = lesson.lessonType == 'VIDEO' ? FileType.video : FileType.custom;
    FilePickerResult? result = await FilePicker.pickFiles(
      type: type,
      allowedExtensions: lesson.lessonType == 'DOCUMENT' ? ['pdf', 'doc', 'docx'] : null,
    );
    
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      if (!mounted) return;
      final provider = context.read<InstructorProvider>();
      
      LessonModel? res;
      if (lesson.lessonType == 'VIDEO') {
        res = await provider.uploadLessonVideo(lesson.id, file);
      } else {
        res = await provider.uploadLessonDocument(lesson.id, file);
      }
      
      if (res != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File uploaded successfully')));
        _refreshCourse();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Upload failed')));
      }
    }
  }

  Future<void> _publishLesson(LessonModel lesson) async {
    final provider = context.read<InstructorProvider>();
    final res = await provider.publishLesson(lesson.id);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson published')));
      _refreshCourse();
    } else if (mounted) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Publish Failed'),
          content: Text(provider.errorMessage ?? 'Failed'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
        )
      );
    }
  }

  Future<void> _publishSection(SectionModel section) async {
    final provider = context.read<InstructorProvider>();
    final res = await provider.publishSection(section.id);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Section published')));
      _refreshCourse();
    } else if (mounted) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Publish Failed'),
          content: Text(provider.errorMessage ?? 'Failed'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Builder'),
        actions: [
          if (_course.status == 'DRAFT')
            TextButton.icon(
              onPressed: _publishCourse,
              icon: const Icon(Icons.public, color: Colors.white),
              label: const Text('Publish Course', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshCourse,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade300,
                            child: _course.thumbnailUrl != null 
                                ? Image.network(_course.thumbnailUrl!, fit: BoxFit.cover)
                                : const Icon(Icons.image, color: Colors.grey),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_course.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text('Status: ${_course.status}'),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _uploadThumbnail,
                                  icon: const Icon(Icons.upload, size: 16),
                                  label: const Text('Update Thumbnail'),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sections', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: _showAddSectionDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Section'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_course.sections.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No sections yet. Create one to begin.')),
                    )
                  else
                    ..._course.sections.map((section) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${section.description}\n${section.isPublished ? "PUBLISHED" : "DRAFT"}'),
                          trailing: section.isPublished ? null : IconButton(
                            icon: const Icon(Icons.publish, color: Colors.blue),
                            onPressed: () => _publishSection(section),
                          ),
                          children: [
                            const Divider(),
                            ...section.lessons.map((lesson) {
                              return ListTile(
                                leading: Icon(
                                  lesson.lessonType == 'VIDEO' ? Icons.play_circle :
                                  lesson.lessonType == 'DOCUMENT' ? Icons.picture_as_pdf :
                                  Icons.text_snippet,
                                ),
                                title: Text(lesson.title),
                                subtitle: Text('${lesson.lessonType} • ${lesson.isPublished ? "PUBLISHED" : "DRAFT"}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!lesson.isPublished)
                                      IconButton(
                                        icon: const Icon(Icons.publish, color: Colors.blue),
                                        tooltip: 'Publish Lesson',
                                        onPressed: () => _publishLesson(lesson),
                                      ),
                                    if (lesson.lessonType != 'TEXT')
                                      IconButton(
                                        icon: const Icon(Icons.upload_file),
                                        tooltip: 'Upload Media',
                                        onPressed: () => _uploadLessonMedia(lesson),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextButton.icon(
                                onPressed: () => _showAddLessonDialog(section),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Lesson'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
