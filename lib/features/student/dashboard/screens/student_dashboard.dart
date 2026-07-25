import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/shared/providers/course_provider.dart';
import 'package:flutter_lms/features/student/providers/student_provider.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/shared/models/dashboard_stats_model.dart';
import 'package:flutter_lms/features/student/courses/screens/student_course_view_page.dart';
import 'package:flutter_lms/features/student/courses/screens/course_details_page.dart';
import 'package:flutter_lms/features/auth/screens/login_page.dart';
import 'package:flutter_lms/features/profile/screens/student_profile_page.dart';
import 'package:flutter_lms/features/admin/providers/admin_provider.dart';
import 'package:flutter_lms/shared/widgets/notification_bell.dart';
import 'package:flutter_lms/shared/widgets/dashboard_stats_card.dart';
import 'package:flutter_lms/shared/widgets/empty_state.dart';

class StudentDashboard extends StatefulWidget {
  final String email;
  const StudentDashboard({super.key, required this.email});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  DashboardStatsModel? _stats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
    final studentProvider = context.read<StudentProvider>();
    await provider.fetchCourses();
    await provider.fetchMyEnrollments();
    _stats = await studentProvider.fetchDashboardStats();
    
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
          const NotificationBell(),
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
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
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
      return const EmptyState(
        title: 'No courses available',
        description: 'Check back later for new and exciting courses!',
        icon: Icons.search_off,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 24),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
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
                  Hero(
                    tag: 'course_image_${course.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        course.thumbnailUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              course.title,
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (course.level.isNotEmpty)
                            Chip(
                              label: Text(course.level.replaceAll('_', ' ')),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              course.allocatedInstructorEmail.split('@')[0],
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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

    return Column(
      children: [
        if (_stats != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DashboardStatsCard(
                    title: 'Active',
                    value: '${_stats!.activeEnrollments}',
                    icon: Icons.play_circle_fill,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: DashboardStatsCard(
                    title: 'Completed',
                    value: '${_stats!.completedCourses}',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: enrollments.isEmpty
              ? provider.errorMessage != null
                  ? Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)))
                  : const EmptyState(
                      title: 'No Active Enrollments',
                      description: 'You haven\'t enrolled in any courses yet. Explore the Discover tab to find a course!',
                      icon: Icons.school_outlined,
                    )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: enrollments.length,
                  itemBuilder: (context, index) {
                    final enrollment = enrollments[index];
                    
                    CourseModel? course;
                    final courseObj = enrollment['course'] ?? enrollment['courseId'];
                    
                    if (courseObj is Map) {
                      course = CourseModel.fromJson(courseObj as Map<String, dynamic>);
                    } else if (courseObj is String) {
                      try {
                        course = provider.courses.firstWhere((c) => c.id == courseObj);
                      } catch (_) {
                        course = null;
                      }
                    }
                    
                    if (course == null) return const SizedBox.shrink();

                    final status = enrollment['status'] ?? 'PENDING';
                    
                    // Hide cancelled or rejected courses from My Learning
                    if (status == 'CANCELLED' || status == 'REJECTED') {
                      return const SizedBox.shrink();
                    }

                    final progress = enrollment['progress'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentCourseViewPage(course: course!, studentEmail: widget.email),
                            ),
                          ).then((_) => _loadData());
                        },
                        child: Row(
                          children: [
                            if (course.thumbnailUrl != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                                child: Image.network(
                                  course.thumbnailUrl!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.title,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      course.allocatedInstructorEmail.split('@')[0],
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress / 100,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$progress% Complete',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
