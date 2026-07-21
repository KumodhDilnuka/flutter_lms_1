import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/shared/providers/course_provider.dart';

class CourseCreationPage extends StatefulWidget {
  const CourseCreationPage({super.key});

  @override
  State<CourseCreationPage> createState() => _CourseCreationPageState();
}

class _CourseCreationPageState extends State<CourseCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _instructorEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;

    final newCourse = CourseModel(
      id: '', // Backend should generate ID
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      allocatedInstructorEmail: _instructorEmailController.text.trim(),
    );

    final provider = context.read<CourseProvider>();
    final success = await provider.createCourse(newCourse);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course Created and Allocated!')));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to create course')));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _instructorEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Course')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Course Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Course Title',
                  hintText: 'e.g. Advanced Flutter Development',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Course Description',
                  hintText: 'What will the students learn?',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              
              const Text('Allocate Instructor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextFormField(
                controller: _instructorEmailController,
                decoration: const InputDecoration(
                  labelText: 'Instructor Email',
                  hintText: 'e.g. instructor@example.com',
                  prefixIcon: Icon(Icons.person_pin_rounded),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
                
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createCourse,
                  child: const Text('Create Course'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
