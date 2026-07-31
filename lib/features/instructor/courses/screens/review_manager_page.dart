import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/features/instructor/providers/instructor_provider.dart';
import 'package:flutter_lms/shared/providers/course_provider.dart';
import 'package:flutter_lms/shared/models/review_model.dart';
import 'package:flutter_lms/shared/models/course_model.dart';

class ReviewManagerPage extends StatefulWidget {
  final CourseModel course;

  const ReviewManagerPage({super.key, required this.course});

  @override
  State<ReviewManagerPage> createState() => _ReviewManagerPageState();
}

class _ReviewManagerPageState extends State<ReviewManagerPage> {
  bool _isLoading = false;
  List<ReviewModel> _reviews = [];

  @override
  void initState() {
    super.initState();
    _refreshReviews();
  }

  Future<void> _refreshReviews() async {
    setState(() => _isLoading = true);
    // Instructor service doesn't have fetchCourseReviews right now, but CourseProvider does.
    // We can use CourseProvider to fetch reviews since they are public anyway.
    final provider = context.read<CourseProvider>();
    final fetched = await provider.fetchCourseReviews(widget.course.id);
    if (mounted) {
      setState(() {
        _reviews = fetched;
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Reviews'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? const Center(child: Text('No reviews for this course yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: review.isHidden ? Colors.grey.shade200 : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(review.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(review.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const Icon(Icons.star, color: Colors.amber, size: 20),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(review.comment),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
