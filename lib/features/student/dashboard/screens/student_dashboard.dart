import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/shared/providers/course_provider.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/features/student/courses/screens/student_course_view_page.dart';
import 'package:flutter_lms/features/student/courses/screens/course_details_page.dart';
import 'package:flutter_lms/features/auth/screens/login_page.dart';
import 'package:flutter_lms/features/profile/screens/student_profile_page.dart';
import 'package:flutter_lms/features/admin/providers/admin_provider.dart';

class StudentDashboard extends StatefulWidget {
  final String email;
  const StudentDashboard({super.key, required this.email});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().fetchCategories();
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final provider = context.read<CourseProvider>();
    await provider.fetchCourses();
    await provider.fetchMyEnrollments();
    
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentProfilePage(email: widget.email),
                ),
              );
            },
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.explore), text: 'Discover'),
            Tab(icon: Icon(Icons.school), text: 'My Learning'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDiscoverTab(),
                _buildMyLearningTab(),
              ],
            ),
    );
  }

  Widget _buildDiscoverTab() {
    final provider = context.watch<CourseProvider>();
    final courses = provider.courses;

    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No courses available yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseDetailsPage(course: course),
                ),
              ).then((_) => _loadData()); // Refresh state on return
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.thumbnailUrl != null)
                  Image.network(course.thumbnailUrl!, height: 160, width: double.infinity, fit: BoxFit.cover)
                else
                  Container(height: 160, width: double.infinity, color: Colors.grey.shade300, child: const Icon(Icons.image, size: 64, color: Colors.grey)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(course.shortDescription, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(course.allocatedInstructorEmail, style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyLearningTab() {
    final provider = context.watch<CourseProvider>();
    final enrollments = provider.myEnrollments;

    if (enrollments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text("You haven't enrolled in any courses.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: enrollments.length,
      itemBuilder: (context, index) {
        final enrollment = enrollments[index];
        final courseJson = enrollment['course'] as Map<String, dynamic>?;
        final status = enrollment['status'] as String? ?? 'PENDING';

        if (courseJson == null) return const SizedBox.shrink();
        final course = CourseModel.fromJson(courseJson);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: course.thumbnailUrl != null ? NetworkImage(course.thumbnailUrl!) : null,
              child: course.thumbnailUrl == null ? const Icon(Icons.book) : null,
            ),
            title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Status: $status', style: TextStyle(color: status == 'APPROVED' ? Colors.green : Colors.orange)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (status == 'APPROVED') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentCourseViewPage(course: course, studentEmail: widget.email),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your enrollment is pending approval.')));
              }
            },
          ),
        );
      },
    );
  }
}
