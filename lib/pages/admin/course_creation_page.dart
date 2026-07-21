import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/course_models.dart';

class CourseCreationPage extends StatefulWidget {
  const CourseCreationPage({super.key});

  @override
  State<CourseCreationPage> createState() => _CourseCreationPageState();
}

class _CourseCreationPageState extends State<CourseCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  List<Map<String, dynamic>> _instructors = [];
  String? _selectedInstructorEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstructors();
  }

  Future<void> _loadInstructors() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '[]';
    final users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
    
    // Filter out only instructors
    final instructors = users.where((u) {
      final userMap = u['user'] ?? u;
      return userMap['role']?.toString().toUpperCase() == 'INSTRUCTOR';
    }).toList();

    setState(() {
      _instructors = instructors;
      _isLoading = false;
    });
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInstructorEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an instructor')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getString('courses') ?? '[]';
    final List<dynamic> currentCourses = jsonDecode(coursesJson);

    final newCourse = CourseModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      allocatedInstructorEmail: _selectedInstructorEmail!,
    );

    currentCourses.add(newCourse.toJson());
    await prefs.setString('courses', jsonEncode(currentCourses));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course Created and Allocated!')));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

              if (_instructors.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: const Text(
                    'No instructors found! Please register an instructor account first before creating a course.',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Instructor',
                    prefixIcon: Icon(Icons.person_pin_rounded),
                  ),
                  value: _selectedInstructorEmail,
                  items: _instructors.map((inst) {
                    final userMap = inst['user'] ?? inst;
                    final email = userMap['email'].toString();
                    final name = userMap['fullName']?.toString() ?? email;
                    return DropdownMenuItem(
                      value: email,
                      child: Text('$name ($email)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedInstructorEmail = val;
                    });
                  },
                ),
                
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _instructors.isEmpty ? null : _createCourse,
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
