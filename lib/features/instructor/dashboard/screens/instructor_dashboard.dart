import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/features/instructor/providers/instructor_provider.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/features/instructor/courses/screens/course_manager_page.dart';
import 'package:flutter_lms/features/instructor/courses/screens/course_creation_page.dart';
import 'package:flutter_lms/features/auth/screens/login_page.dart';
import 'package:flutter_lms/features/profile/screens/instructor_profile_page.dart';
import 'package:flutter_lms/shared/widgets/notification_bell.dart';
import 'package:flutter_lms/shared/widgets/dashboard_stats_card.dart';
import 'package:flutter_lms/shared/models/dashboard_stats_model.dart';

import 'package:flutter_lms/shared/widgets/empty_state.dart';

class InstructorDashboard extends StatefulWidget {
  final String email;
  const InstructorDashboard({super.key, required this.email});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  List<CourseModel> _myCourses = [];
  bool _isLoading = true;
  DashboardStatsModel? _stats;

  @override
  void initState() {
    super.initState();
    _loadMyCourses();
  }

  Future<void> _loadMyCourses() async {
    setState(() => _isLoading = true);
    final provider = context.read<InstructorProvider>();
    await provider.fetchMyCourses();
    _stats = await provider.fetchDashboardStats();

    setState(() {
      _myCourses = provider.myCourses;
      _isLoading = false;
    });
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
        title: const Text('My Allocated Courses'),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InstructorProfilePage(email: widget.email),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_stats != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: DashboardStatsCard(
                            title: 'Total Students',
                            value: '${_stats!.totalStudents}',
                            icon: Icons.people,
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: DashboardStatsCard(
                            title: 'Total Courses',
                            value: '${_myCourses.length}', // or _stats!.totalCourses
                            icon: Icons.library_books,
                            color: Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: DashboardStatsCard(
                            title: 'Revenue',
                            value: '\$${_stats!.totalRevenue}',
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _myCourses.isEmpty
                      ? const EmptyState(
                          title: 'No Allocated Courses',
                          description: 'You haven\'t been allocated any courses yet. Create one or contact an admin.',
                          icon: Icons.assignment_ind_outlined,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _myCourses.length,
                          itemBuilder: (context, index) {
                            final course = _myCourses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CourseManagerPage(course: course),
                                    ),
                                  );
                                  _loadMyCourses(); // Reload in case sections/lessons were added
                                },
                                child: Padding(
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
                                      Text(
                                        course.shortDescription,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Icon(Icons.folder_open, size: 18, color: Theme.of(context).colorScheme.primary),
                                          const SizedBox(width: 6),
                                          Text('${course.sections.length} Sections', 
                                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                                          const Spacer(),
                                          Text('Manage Content', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                                          const SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).colorScheme.primary),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CourseCreationPage()),
          );
          _loadMyCourses(); // Reload after creating
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Course'),
      ),
    );
  }
}
