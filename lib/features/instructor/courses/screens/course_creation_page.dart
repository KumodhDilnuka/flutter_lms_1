import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/features/admin/providers/admin_provider.dart';
import 'package:flutter_lms/features/instructor/providers/instructor_provider.dart';

class CourseCreationPage extends StatefulWidget {
  const CourseCreationPage({super.key});

  @override
  State<CourseCreationPage> createState() => _CourseCreationPageState();
}

class _CourseCreationPageState extends State<CourseCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _descController = TextEditingController();
  final _languageController = TextEditingController(text: 'English');
  final _requirementsController = TextEditingController();
  final _outcomesController = TextEditingController();
  final _audienceController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedLevel = 'BEGINNER';

  final List<String> _levels = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'ALL_LEVELS'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescController.dispose();
    _descController.dispose();
    _languageController.dispose();
    _requirementsController.dispose();
    _outcomesController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    final provider = context.read<InstructorProvider>();
    
    // Parse comma separated lists
    List<String> parseList(String text) => text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final payload = {
      'title': _titleController.text.trim(),
      'shortDescription': _shortDescController.text.trim(),
      'description': _descController.text.trim(),
      'categoryId': _selectedCategoryId,
      'level': _selectedLevel,
      'language': _languageController.text.trim(),
      'requirements': parseList(_requirementsController.text),
      'learningOutcomes': parseList(_outcomesController.text),
      'targetAudience': parseList(_audienceController.text),
    };

    final success = await provider.createCourse(payload);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course Created Successfully!')));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to create course')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final instructorProvider = context.watch<InstructorProvider>();

    // Only show active categories
    final activeCategories = adminProvider.categories.where((c) => c.isActive).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Course')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Basic Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Course Title', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _shortDescController,
                decoration: const InputDecoration(labelText: 'Short Description (Subtitle)', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Full Description', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              const Text('Classification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              if (adminProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (activeCategories.isEmpty)
                const Text('No active categories found. Ask an admin to create one.', style: TextStyle(color: Colors.red))
              else
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: activeCategories.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedLevel,
                      decoration: const InputDecoration(labelText: 'Level', border: OutlineInputBorder()),
                      items: _levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                      onChanged: (val) => setState(() => _selectedLevel = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _languageController,
                      decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Details (Comma Separated)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextFormField(
                controller: _requirementsController,
                decoration: const InputDecoration(labelText: 'Requirements (e.g. Basic math, Internet)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _outcomesController,
                decoration: const InputDecoration(labelText: 'Learning Outcomes (e.g. Build apps, Master UI)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _audienceController,
                decoration: const InputDecoration(labelText: 'Target Audience (e.g. Beginners, Developers)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: instructorProvider.isLoading ? null : _createCourse,
                  child: instructorProvider.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Course', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
