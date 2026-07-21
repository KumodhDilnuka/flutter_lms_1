import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/course_models.dart';
import 'course_manager_page.dart';
import '../../login_and_signup_pagers/login_page.dart';
import '../profile/instructor_profile_page.dart';

class InstructorDashboard extends StatefulWidget {
  final String email;
  const InstructorDashboard({super.key, required this.email});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  List<CourseModel> _myCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyCourses();
  }

  Future<void> _loadMyCourses() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getString('courses') ?? '[]';
    final List<dynamic> decodedList = jsonDecode(coursesJson);
    
    final allCourses = decodedList.map((e) => CourseModel.fromJson(e)).toList();
    final myCourses = allCourses.where((c) => c.allocatedInstructorEmail == widget.email).toList();

    setState(() {
      _myCourses = myCourses;
      _isLoading = false;
    });
  }

  Future<void> _handleStudentRequest(CourseModel course, String studentEmail, bool approve) async {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = prefs.getString('courses') ?? '[]';
    final List<dynamic> decodedList = jsonDecode(coursesJson);
    
    final allCourses = decodedList.map((e) => CourseModel.fromJson(e)).toList();
    final index = allCourses.indexWhere((c) => c.id == course.id);
    
    if (index != -1) {
      allCourses[index].pendingStudents.remove(studentEmail);
      if (approve) {
        allCourses[index].enrolledStudents.add(studentEmail);
      }
      await prefs.setString('courses', jsonEncode(allCourses.map((e) => e.toJson()).toList()));
      _loadMyCourses();
    }
  }

  void _showPendingRequestsModal(CourseModel course) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final pending = course.pendingStudents;
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enrollment Requests (${pending.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),
                  if (pending.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No pending requests.'),
                    )
                  else
                    ...pending.map((email) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person, color: Colors.orange),
                        title: Text(email, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              tooltip: 'Approve',
                              onPressed: () {
                                _handleStudentRequest(course, email, true);
                                setModalState(() => course.pendingStudents.remove(email));
                                if (course.pendingStudents.isEmpty) Navigator.pop(context);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              tooltip: 'Deny',
                              onPressed: () {
                                _handleStudentRequest(course, email, false);
                                setModalState(() => course.pendingStudents.remove(email));
                                if (course.pendingStudents.isEmpty) Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
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
          : _myCourses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_ind_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No courses allocated to you yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myCourses.length,
                  itemBuilder: (context, index) {
                    final course = _myCourses[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourseManagerPage(course: course),
                            ),
                          );
                          _loadMyCourses(); // Reload in case sections/lessons were added
                        },
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
                                  const Text('Manage Content', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
                                ],
                              ),
                              if (course.pendingStudents.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${course.pendingStudents.length}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Pending Requests', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () => _showPendingRequestsModal(course),
                                      child: const Text('Review', style: TextStyle(color: Colors.orange)),
                                    ),
                                  ],
                                ),
                              ],
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
