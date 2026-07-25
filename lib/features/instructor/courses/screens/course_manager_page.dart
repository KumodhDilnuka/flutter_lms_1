import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_lms/features/instructor/providers/instructor_provider.dart';
import 'package:flutter_lms/features/instructor/courses/screens/quiz_manager_page.dart';
import 'package:flutter_lms/features/instructor/courses/screens/assignment_manager_page.dart';
import 'package:flutter_lms/features/instructor/courses/screens/review_manager_page.dart';
import 'package:flutter_lms/features/instructor/courses/screens/enrollment_manager_page.dart';
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

  Future<void> _removeLessonMedia(LessonModel lesson) async {
    final provider = context.read<InstructorProvider>();
    bool success = false;
    if (lesson.lessonType == 'VIDEO') {
      success = await provider.deleteLessonVideo(lesson.id);
    } else if (lesson.lessonType == 'DOCUMENT') {
      success = await provider.deleteLessonDocument(lesson.id);
    }
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media removed')));
      _refreshCourse();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Remove failed')));
    }
  }

  Future<void> _deleteLesson(LessonModel lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: const Text('Are you sure you want to delete this lesson?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<InstructorProvider>();
      final success = await provider.deleteLesson(lesson.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson deleted')));
        _refreshCourse();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Delete failed')));
      }
    }
  }

  void _showEditLessonDialog(SectionModel section, LessonModel lesson) {
    final titleCtrl = TextEditingController(text: lesson.title);
    final descCtrl = TextEditingController(text: lesson.description);
    final contentCtrl = TextEditingController(text: lesson.textContent ?? '');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Lesson'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                if (lesson.lessonType == 'TEXT')
                  TextField(controller: contentCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Text Content')),
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
                  if (lesson.lessonType == 'TEXT') 'textContent': contentCtrl.text,
                };
                
                final res = await provider.updateLesson(lesson.id, payload);
                if (!mounted) return;
                if (res != null) {
                  Navigator.pop(context);
                  _refreshCourse();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson updated!')));
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
              child: const Text('Save'),
            ),
          ],
        );
      }
    );
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

  Future<void> _removeThumbnail() async {
    final provider = context.read<InstructorProvider>();
    final success = await provider.removeThumbnail(_course.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thumbnail removed')));
      _refreshCourse();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Remove failed')));
    }
  }

  Future<void> _archiveCourse() async {
    final provider = context.read<InstructorProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Archive Course'),
        content: const Text('Are you sure you want to archive this course?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await provider.archiveCourse(_course.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course archived')));
        Navigator.pop(context); // Go back to course list
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Archive failed')));
      }
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
          if (_course.status != 'ARCHIVED')
            IconButton(
              icon: const Icon(Icons.archive, color: Colors.white),
              tooltip: 'Archive Course',
              onPressed: _archiveCourse,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshCourse,
              child: ReorderableListView(
                padding: const EdgeInsets.all(16),
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final section = _course.sections.removeAt(oldIndex);
                  _course.sections.insert(newIndex, section);
                  setState(() {});
                  
                  final provider = context.read<InstructorProvider>();
                  final success = await provider.reorderSection(section.id, newIndex + 1); // API expects 1-indexed or 0-indexed? Let's use newIndex as 1-indexed position maybe, or 0. We'll just pass newIndex.
                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Reorder failed')));
                    _refreshCourse(); // Revert on failure
                  }
                },
                header: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _uploadThumbnail,
                                      icon: const Icon(Icons.upload, size: 16),
                                      label: const Text('Update Thumbnail'),
                                    ),
                                    // if (_course.thumbnailUrl != null) 
                                    //   IconButton(
                                    //     icon: const Icon(Icons.delete, color: Colors.red),
                                    //     tooltip: 'Remove Thumbnail',
                                    //     onPressed: _removeThumbnail,
                                    //   ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sections', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showAddSectionDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Section'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => QuizManagerPage(course: _course)),
                              );
                            },
                            icon: const Icon(Icons.quiz, size: 18),
                            label: const Text('Quizzes'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AssignmentManagerPage(course: _course)),
                              );
                            },
                            icon: const Icon(Icons.assignment, size: 18),
                            label: const Text('Assignments'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ReviewManagerPage(course: _course)),
                              );
                            },
                            icon: const Icon(Icons.rate_review, size: 18),
                            label: const Text('Reviews'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => EnrollmentManagerPage(course: _course)),
                              );
                            },
                            icon: const Icon(Icons.how_to_reg, size: 18),
                            label: const Text('Enrollments'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              children: [
                  if (_course.sections.isEmpty)
                    const Padding(
                      key: ValueKey('empty'),
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No sections yet. Create one to begin.')),
                    )
                  else
                    ..._course.sections.map((section) {
                      return Card(
                        key: ValueKey(section.id),
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
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: section.lessons.length,
                              onReorder: (oldIndex, newIndex) async {
                                if (newIndex > oldIndex) {
                                  newIndex -= 1;
                                }
                                final lesson = section.lessons.removeAt(oldIndex);
                                section.lessons.insert(newIndex, lesson);
                                setState(() {});
                                
                                final provider = context.read<InstructorProvider>();
                                final success = await provider.reorderLesson(lesson.id, newIndex + 1);
                                if (!success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Reorder failed')));
                                  _refreshCourse();
                                }
                              },
                              itemBuilder: (context, index) {
                                final lesson = section.lessons[index];
                                return ListTile(
                                  key: ValueKey(lesson.id),
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
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.grey),
                                        tooltip: 'Edit Lesson',
                                        onPressed: () => _showEditLessonDialog(section, lesson),
                                      ),
                                      if (lesson.lessonType != 'TEXT') ...[
                                        IconButton(
                                          icon: const Icon(Icons.upload_file),
                                          tooltip: 'Upload Media',
                                          onPressed: () => _uploadLessonMedia(lesson),
                                        ),
                                        if (lesson.videoUrl != null || lesson.documentUrl != null)
                                          IconButton(
                                            icon: const Icon(Icons.link_off, color: Colors.orange),
                                            tooltip: 'Remove Media',
                                            onPressed: () => _removeLessonMedia(lesson),
                                          ),
                                      ],
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Delete Lesson',
                                        onPressed: () => _deleteLesson(lesson),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
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
