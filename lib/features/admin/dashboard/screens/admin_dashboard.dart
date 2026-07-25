import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/features/auth/screens/login_page.dart';
import 'package:flutter_lms/features/admin/categories/screens/category_management_page.dart';
import 'package:flutter_lms/features/admin/users/screens/admin_users_page.dart';
import 'package:flutter_lms/features/admin/providers/admin_provider.dart';
import 'package:flutter_lms/shared/widgets/notification_bell.dart';
import 'package:flutter_lms/shared/widgets/dashboard_stats_card.dart';
import 'package:flutter_lms/shared/widgets/empty_state.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final provider = context.read<AdminProvider>();
    
    // Store errors
    List<String> errors = [];
    
    await provider.fetchAllCourses();
    if (provider.errorMessage != null) {
      errors.add('Courses: ${provider.errorMessage}');
    }
    
    await provider.fetchUsers();
    if (provider.errorMessage != null) {
      errors.add('Users: ${provider.errorMessage}');
    }

    await provider.fetchCategories();
    if (provider.errorMessage != null) {
      errors.add('Categories: ${provider.errorMessage}');
    }

    if (mounted) {
      if (errors.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('API Error'),
            content: SingleChildScrollView(child: Text(errors.join('\n\n'))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _archiveCourse(CourseModel course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Course'),
        content: Text('Are you sure you want to archive "${course.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = context.read<AdminProvider>();
      final success = await provider.archiveCourseAsAdmin(course.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course archived successfully')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Archive failed')));
        }
      }
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
    final provider = context.watch<AdminProvider>();
    final courses = provider.adminCourses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          const NotificationBell(),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.white, size: 48),
                  SizedBox(height: 16),
                  Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_rounded),
              title: const Text('Manage Users'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminUsersPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.category_rounded),
              title: const Text('Manage Categories'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoryManagementPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: DashboardStatsCard(
                            title: 'Total Users',
                            value: '${provider.users.length}',
                            icon: Icons.people,
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: DashboardStatsCard(
                            title: 'Total Courses',
                            value: '${courses.length}',
                            icon: Icons.library_books,
                            color: Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: DashboardStatsCard(
                            title: 'Categories',
                            value: '${provider.categories.length}',
                            icon: Icons.category,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: courses.isEmpty
                      ? const EmptyState(
                          title: 'No Courses Found',
                          description: 'There are currently no courses in the system.',
                          icon: Icons.library_books_outlined,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: courses.length,
                          itemBuilder: (context, index) {
                            final course = courses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            course.title,
                                            style: Theme.of(context).textTheme.titleLarge,
                                          ),
                                        ),
                                        if (course.status == 'ARCHIVED')
                                          Chip(
                                            label: const Text('Archived'),
                                            backgroundColor: Colors.grey.shade300,
                                            visualDensity: VisualDensity.compact,
                                          )
                                        else
                                          IconButton(
                                            icon: const Icon(Icons.archive_outlined, color: Colors.red),
                                            tooltip: 'Archive Course',
                                            onPressed: () => _archiveCourse(course),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      course.shortDescription,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Icon(Icons.person, size: 16, color: Theme.of(context).colorScheme.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            course.allocatedInstructorEmail.isEmpty 
                                              ? 'Instructor: Unassigned'
                                              : 'Instructor: ${course.allocatedInstructorEmail.split('@')[0]}',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
