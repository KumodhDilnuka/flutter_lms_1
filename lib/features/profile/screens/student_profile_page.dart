import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/shared/models/user_model.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';
import 'package:flutter_lms/shared/providers/course_provider.dart';
import 'package:flutter_lms/shared/widgets/app_card.dart';
import 'package:flutter_lms/shared/widgets/app_button.dart';
import 'package:flutter_lms/shared/widgets/section_header.dart';
import 'package:flutter_lms/features/auth/screens/login_page.dart';

class StudentProfilePage extends StatefulWidget {
  final String email;

  const StudentProfilePage({super.key, required this.email});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  User? _user;
  bool _isLoading = true;
  int _enrolledCourseCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final auth = context.read<AuthProvider>();
    final courseProvider = context.read<CourseProvider>();
    final enrolledCount = courseProvider.myEnrollments
        .where((e) => e['status'] == 'APPROVED')
        .length;

    setState(() {
      _user = auth.currentUser;
      _enrolledCourseCount = enrolledCount;
      _isLoading = false;
    });
  }

  void _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _logoutAll() async {
    await context.read<AuthProvider>().logoutAllDevices();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _showEditProfileDialog() {
    final firstNameCtrl = TextEditingController(text: _user?.firstName ?? '');
    final lastNameCtrl = TextEditingController(text: _user?.lastName ?? '');
    final bioCtrl = TextEditingController(text: _user?.bio ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Edit Profile'),
              const SizedBox(height: 16),
              TextField(
                controller: firstNameCtrl,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Changes',
                icon: Icons.save_rounded,
                onPressed: () {
                  // Profile update API not yet connected — show confirmation
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile update will be available when API is connected.')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;
    final horizontalPadding = isWide ? screenWidth * 0.1 : 20.0;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Profile')),
        body: const Center(child: Text('Profile not found.')),
      );
    }

    final user = _user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
        child: Column(
          children: [
            // Header Card
            AppCard(
              elevation: 2,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.school_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('${user.firstName} ${user.lastName}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(user.bio!, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                  const SizedBox(height: 4),
                  Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
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
                  const SizedBox(height: 16),
                  // Edit Profile Button
                  AppButton(
                    label: 'Edit Profile',
                    icon: Icons.edit_rounded,
                    isOutlined: true,
                    onPressed: _showEditProfileDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    child: Column(
                      children: [
                        Icon(Icons.menu_book_rounded, size: 28, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 8),
                        Text('$_enrolledCourseCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Enrolled Courses', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    child: Column(
                      children: [
                        Icon(Icons.verified_rounded, size: 28, color: user.emailVerified ? Colors.green : Colors.orange),
                        const SizedBox(height: 8),
                        Text(user.emailVerified ? 'Yes' : 'No', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Email Verified', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Student Information Section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Student Information'),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.email_outlined, 'Email', user.email),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.school_outlined, 'Status', user.status),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.badge_outlined, 'Role', user.role),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Logout Button
            AppButton(
              label: 'Logout',
              icon: Icons.logout,
              isOutlined: true,
              color: Colors.red,
              onPressed: _logout,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Logout from All Devices',
              icon: Icons.phonelink_erase_rounded,
              isOutlined: true,
              color: Colors.red.shade900,
              onPressed: _logoutAll,
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
