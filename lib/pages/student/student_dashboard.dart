import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/course_models.dart';
import 'student_course_view_page.dart';
import '../../login_and_signup_pagers/login_page.dart';
import '../profile/student_profile_page.dart';

class StudentDashboard extends StatefulWidget {
  final String email;
  const StudentDashboard({super.key, required this.email});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  List<CourseModel> _allCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getString('courses') ?? '[]';
    final List<dynamic> decodedList = jsonDecode(coursesJson);
    
    setState(() {
      _allCourses = decodedList.map((e) => CourseModel.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _requestEnrollment(CourseModel course) async {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getString('courses') ?? '[]';
    final List<dynamic> decodedList = jsonDecode(coursesJson);
    
    final allCourses = decodedList.map((e) => CourseModel.fromJson(e)).toList();
    final index = allCourses.indexWhere((c) => c.id == course.id);
    
    if (index != -1) {
      if (!allCourses[index].pendingStudents.contains(widget.email)) {
        allCourses[index].pendingStudents.add(widget.email);
        await prefs.setString('courses', jsonEncode(allCourses.map((e) => e.toJson()).toList()));
        _loadCourses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enrollment Request Sent!')));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Courses'),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allCourses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_stories_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No courses available yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allCourses.length,
                  itemBuilder: (context, index) {
                    final course = _allCourses[index];
                    final isEnrolled = course.enrolledStudents.contains(widget.email);
                    final isPending = course.pendingStudents.contains(widget.email);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: isEnrolled 
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentCourseViewPage(course: course, studentEmail: widget.email),
                                ),
                              );
                            }
                          : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 8),
                              Text(course.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.folder_open, size: 16, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text('${course.sections.length} Sections', 
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  if (isEnrolled) ...[
                                    const Text('View Course', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
                                  ] else if (isPending) ...[
                                    const Text('Pending Approval', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.access_time_filled, size: 16, color: Colors.orange),
                                  ] else ...[
                                    ElevatedButton(
                                      onPressed: () => _requestEnrollment(course),
                                      style: ElevatedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                      child: const Text('Request Enrollment'),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
