import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../../login_and_signup_pagers/login_page.dart';

class InstructorProfilePage extends StatefulWidget {
  final String email;

  const InstructorProfilePage({super.key, required this.email});

  @override
  State<InstructorProfilePage> createState() => _InstructorProfilePageState();
}

class _InstructorProfilePageState extends State<InstructorProfilePage> {
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
        appBar: AppBar(title: const Text('Instructor Profile')),
        body: const Center(child: Text('Profile not found.')),
      );
    }

    final user = _profile!.user;
    final profile = _profile!.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor Profile'),
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
                      backgroundColor: Colors.amber.withValues(alpha: 0.15),
                      child: const Icon(Icons.person_pin_rounded, size: 48, color: Colors.amber),
                    ),
                    const SizedBox(height: 16),
                    Text(user.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    if (profile.headline != null && profile.headline!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(profile.headline!, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 15)),
                    ],
                    const SizedBox(height: 4),
                    Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${user.role} • ${user.status}',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Credentials Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Professional Credentials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const Divider(height: 24),
                    _buildDetailRow(Icons.school_outlined, 'Highest Qualification', profile.qualification ?? 'Not provided'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.work_history_outlined, 'Experience', '${profile.experienceYears ?? 0} Years'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Expertise Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Areas of Expertise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const Divider(height: 24),
                    if (profile.expertise.isEmpty)
                      Text('No expertise tags set.', style: TextStyle(color: Colors.grey.shade600))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.expertise.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: Text(skill, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Biography Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Biography', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const Divider(height: 24),
                    Text(
                      profile.biography ?? 'No biography provided yet.',
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.5),
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
