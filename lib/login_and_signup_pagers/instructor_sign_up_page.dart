import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'otp_verification_page.dart';

class InstructorSignupPage extends StatefulWidget {
  const InstructorSignupPage({super.key});

  @override
  State<InstructorSignupPage> createState() => _InstructorSignupPageState();
}

class _InstructorSignupPageState extends State<InstructorSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _headlineController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _expController = TextEditingController();
  final _bioController = TextEditingController();
  final _expertiseController = TextEditingController();

  final List<String> _expertiseList = ['Flutter', 'Dart', 'Firebase'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _headlineController.dispose();
    _qualificationController.dispose();
    _expController.dispose();
    _bioController.dispose();
    _expertiseController.dispose();
    super.dispose();
  }

  void _addExpertise() {
    final text = _expertiseController.text.trim();
    if (text.isNotEmpty && !_expertiseList.contains(text)) {
      setState(() {
        _expertiseList.add(text);
        _expertiseController.clear();
      });
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

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
      role: 'INSTRUCTOR',
    );

    final profileModel = ProfileModel(
      id: '${userId}_p',
      userId: userId,
      headline: _headlineController.text.trim(),
      qualification: _qualificationController.text.trim(),
      experienceYears: int.tryParse(_expController.text.trim()) ?? 0,
      expertise: _expertiseList,
      biography: _bioController.text.trim(),
    );

    final completeProfile = CompleteProfile(user: userModel, profile: profileModel);

    if (!mounted) return;
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
      appBar: AppBar(title: const Text('Instructor Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Instructor Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text('Professional Credentials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                // Headline
                TextFormField(
                  controller: _headlineController,
                  decoration: const InputDecoration(
                    labelText: 'Professional Headline',
                    hintText: 'e.g. Senior Flutter Instructor',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Qualification & Experience Years
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _qualificationController,
                        decoration: const InputDecoration(
                          labelText: 'Highest Qualification',
                          hintText: 'e.g. BSc in Software Engineering',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _expController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Exp. Years',
                          hintText: 'e.g. 5',
                        ),
                        validator: (v) => v == null || int.tryParse(v) == null ? 'Number' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Expertise Tag Input
                const Text('Areas of Expertise', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expertiseController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. REST APIs, State Management',
                        ),
                        onFieldSubmitted: (_) => _addExpertise(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addExpertise,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _expertiseList.map((skill) {
                    return Chip(
                      label: Text(skill),
                      onDeleted: () => setState(() => _expertiseList.remove(skill)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Biography
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Biography',
                    hintText: 'Share a brief background about your teaching experience and career...',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
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
