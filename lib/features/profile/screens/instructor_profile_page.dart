import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/shared/models/user_model.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';
import 'package:flutter_lms/shared/widgets/app_card.dart';
import 'package:flutter_lms/shared/widgets/app_button.dart';
import 'package:flutter_lms/shared/widgets/section_header.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_lms/features/auth/screens/login_page.dart';
import 'package:flutter_lms/shared/providers/user_provider.dart';
import 'package:flutter_lms/features/instructor/providers/instructor_provider.dart';
import 'package:flutter_lms/shared/models/instructor_profile_model.dart';
import 'package:flutter_lms/features/profile/screens/edit_profile_page.dart';
import 'package:flutter_lms/features/profile/screens/change_password_page.dart';
class InstructorProfilePage extends StatefulWidget {
  final String email;

  const InstructorProfilePage({super.key, required this.email});

  @override
  State<InstructorProfilePage> createState() => _InstructorProfilePageState();
}

class _InstructorProfilePageState extends State<InstructorProfilePage> {
  User? _user;
  InstructorProfileModel? _instructorProfile;
  bool _isLoading = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final userProvider = context.read<UserProvider>();
    final instructorProvider = context.read<InstructorProvider>();
    
    Future.wait([
      userProvider.fetchMyProfile(),
      instructorProvider.fetchMyProfile(),
    ]).then((_) {
      if (mounted) {
        setState(() {
          _user = userProvider.currentUserProfile ?? context.read<AuthProvider>().currentUser;
          _instructorProfile = instructorProvider.instructorProfile;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      final success = await context.read<UserProvider>().uploadProfileImage(File(image.path));
      if (success && mounted) {
        _loadProfile();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
      }
    }
  }

  Future<void> _deleteImage() async {
    final success = await context.read<UserProvider>().deleteProfileImage();
    if (success && mounted) {
      _loadProfile();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete image')));
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload new picture'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage();
              },
            ),
            if (_user?.profileImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove current picture', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteImage();
                },
              ),
          ],
        ),
      ),
    );
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    ).then((_) {
      if (mounted) _loadProfile(); // reload after returning
    });
  }

  void _deactivateAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Account'),
        content: const Text('Are you sure you want to deactivate your account? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<UserProvider>().deactivateAccount();
      if (success && mounted) {
        _logout();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to deactivate account')));
      }
    }
  }

  void _showEditInstructorDialog() {
    final titleCtrl = TextEditingController(text: _instructorProfile?.title ?? '');
    final deptCtrl = TextEditingController(text: _instructorProfile?.department ?? '');
    final yearsCtrl = TextEditingController(text: _instructorProfile?.yearsOfExperience?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit Instructor Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title (e.g. Professor)')),
            const SizedBox(height: 12),
            TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
            const SizedBox(height: 12),
            TextField(controller: yearsCtrl, decoration: const InputDecoration(labelText: 'Years of Experience'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            AppButton(
              label: 'Save',
              onPressed: () async {
                final payload = {
                  'title': titleCtrl.text.trim(),
                  'department': deptCtrl.text.trim(),
                  'yearsOfExperience': int.tryParse(yearsCtrl.text.trim()) ?? 0,
                };
                bool success;
                if (_instructorProfile == null) {
                  success = await context.read<InstructorProvider>().createProfile(payload);
                } else {
                  success = await context.read<InstructorProvider>().updateProfile(payload);
                }
                
                if (success && mounted) {
                  Navigator.pop(context);
                  _loadProfile();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save info')));
                }
              },
            ),
          ],
        ),
      ),
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
        appBar: AppBar(title: const Text('Instructor Profile')),
        body: const Center(child: Text('Profile not found.')),
      );
    }

    final user = _user!;

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
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
        child: Column(
          children: [
            // Header Card
            AppCard(
              elevation: 2,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showImageOptions,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.amber.withValues(alpha: 0.15),
                          backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                          child: user.profileImageUrl == null ? const Icon(Icons.person_pin_rounded, size: 48, color: Colors.amber) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
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
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${user.role} • ${user.status}',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 12),
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

            // Professional Credentials Card
            // AppCard(
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         children: [
            //           const SectionHeader(title: 'Professional Credentials'),
            //           IconButton(
            //             icon: const Icon(Icons.edit, size: 20),
            //             onPressed: _showEditInstructorDialog,
            //           ),
            //         ],
            //       ),
            //       const Divider(height: 24),
            //       if (_instructorProfile != null && _instructorProfile!.title != null) ...[
            //         _buildDetailRow(Icons.work_outline, 'Title', _instructorProfile!.title!),
            //         const SizedBox(height: 16),
            //       ],
            //       if (_instructorProfile != null && _instructorProfile!.department != null) ...[
            //         _buildDetailRow(Icons.business_outlined, 'Department', _instructorProfile!.department!),
            //         const SizedBox(height: 16),
            //       ],
            //       if (_instructorProfile != null && _instructorProfile!.yearsOfExperience != null) ...[
            //         _buildDetailRow(Icons.timeline_outlined, 'Experience', '${_instructorProfile!.yearsOfExperience!} years'),
            //         const SizedBox(height: 16),
            //       ],
            //       _buildDetailRow(Icons.email_outlined, 'Email', user.email),
            //       const SizedBox(height: 16),
            //       _buildDetailRow(Icons.school_outlined, 'Status', user.status),
            //       const SizedBox(height: 16),
            //       _buildDetailRow(Icons.verified_outlined, 'Verified', user.emailVerified ? 'Yes' : 'No'),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 20),

            // Biography Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Biography'),
                  const Divider(height: 24),
                  Text(
                    user.bio ?? 'No biography provided.',
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Change Password & Deactivate
            AppButton(
              label: 'Change Password',
              icon: Icons.lock_reset,
              isOutlined: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Deactivate Account',
              icon: Icons.warning_rounded,
              isOutlined: true,
              color: Colors.orange.shade800,
              onPressed: _deactivateAccount,
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
