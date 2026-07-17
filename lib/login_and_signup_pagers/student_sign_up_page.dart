import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'otp_verification_page.dart';

class StudentSignupPage extends StatefulWidget {
  const StudentSignupPage({super.key});

  @override
  State<StudentSignupPage> createState() => _StudentSignupPageState();
}

class _StudentSignupPageState extends State<StudentSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _goalController = TextEditingController();

  String? _selectedDateOfBirth;
  String _selectedEducation = 'Undergraduate';
  final List<String> _learningGoals = ['Learn Flutter'];

  final List<String> _educationOptions = [
    'High School',
    'Undergraduate',
    'Postgraduate',
    'Diploma',
    'Self-Taught / Other',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2002, 5, 15),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _addGoal() {
    final text = _goalController.text.trim();
    if (text.isNotEmpty && !_learningGoals.contains(text)) {
      setState(() {
        _learningGoals.add(text);
        _goalController.clear();
      });
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Date of Birth')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '[]';
    final users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));

    final emailExists = users.any((u) {
      final userMap = u['user'] ?? u;
      return userMap['email'] == _emailController.text.trim();
    });

    if (emailExists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email is already registered!')),
      );
      return;
    }

    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final userModel = UserModel(
      id: userId,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      fullName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: 'STUDENT',
    );

    final profileModel = ProfileModel(
      id: '${userId}_p',
      userId: userId,
      dateOfBirth: _selectedDateOfBirth,
      educationLevel: _selectedEducation,
      learningGoals: _learningGoals,
    );

    final completeProfile = CompleteProfile(user: userModel, profile: profileModel);

    if (!mounted) return;
    // Navigate to OTP page for email verification
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationPage(profileToSave: completeProfile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Student Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // First Name & Last Name
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'First Name'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'Last Name'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),

                // Password & Confirm
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password'),
                        validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Confirm Password'),
                        validator: (v) => v != _passwordController.text ? 'No match' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date of Birth Selector
                InkWell(
                  onTap: _pickDateOfBirth,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date of Birth'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedDateOfBirth ?? 'Select Birth Date (YYYY-MM-DD)',
                            style: TextStyle(color: _selectedDateOfBirth == null ? Colors.grey : null)),
                        const Icon(Icons.calendar_today_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Education Level Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedEducation,
                  decoration: const InputDecoration(labelText: 'Education Level'),
                  items: _educationOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _selectedEducation = val!),
                ),
                const SizedBox(height: 16),

                // Learning Goals Tag Input
                const Text('Learning Goals', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _goalController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Improve mobile development skills',
                        ),
                        onFieldSubmitted: (_) => _addGoal(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addGoal,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _learningGoals.map((goal) {
                    return Chip(
                      label: Text(goal),
                      onDeleted: () => setState(() => _learningGoals.remove(goal)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signup,
                    child: const Text('Proceed to Email Verification'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Already have an account? Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
