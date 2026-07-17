import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../../login_and_signup_pagers/login_page.dart';

class StudentProfilePage extends StatefulWidget {
  final String email;

  const StudentProfilePage({super.key, required this.email});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  CompleteProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '[]';
    final users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));

    for (final u in users) {
      final userMap = u['user'] ?? u;
      if (userMap['email'] == widget.email) {
        if (u['user'] != null && u['profile'] != null) {
          _profile = CompleteProfile.fromJson(u);
        } else {
          // Fallback if stored as flat model
          final userModel = UserModel.fromJson(userMap);
          final profileModel = ProfileModel(id: '${userModel.id}_p', userId: userModel.id);
          _profile = CompleteProfile(user: userModel, profile: profileModel);
        }
        break;
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Profile')),
        body: const Center(child: Text('Profile not found.')),
      );
    }

    final user = _profile!.user;
    final profile = _profile!.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.school_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(user.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${user.role} • ${user.status}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Profile Details Section
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Academic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const Divider(height: 24),
                    _buildDetailRow(Icons.calendar_today_rounded, 'Date of Birth', profile.dateOfBirth ?? 'Not provided'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.account_balance_rounded, 'Education Level', profile.educationLevel ?? 'Not provided'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Learning Goals Section
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Learning Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const Divider(height: 24),
                    if (profile.learningGoals.isEmpty)
                      Text('No goals set yet.', style: TextStyle(color: Colors.grey.shade600))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.learningGoals.map((g) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                            ),
                            child: Text(g, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500)),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
