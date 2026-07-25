import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/shared/models/course_model.dart';
import 'package:flutter_lms/shared/models/review_model.dart';
import 'package:flutter_lms/shared/providers/course_provider.dart';

class CourseDetailsPage extends StatefulWidget {
  final CourseModel course;

  const CourseDetailsPage({super.key, required this.course});

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  bool _isEnrolling = false;
  late CourseModel _course;
  List<ReviewModel> _reviews = [];

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final provider = context.read<CourseProvider>();
    final detailedCourse = await provider.getCourseDetails(_course.id);
    final reviews = await provider.fetchCourseReviews(_course.id);
    if (detailedCourse != null && mounted) {
      setState(() {
        _course = detailedCourse;
        _reviews = reviews;
      });
    }
  }

  void _showReviewDialog() {
    int rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Write a Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setDialogState(() => rating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final provider = context.read<CourseProvider>();
                    await provider.createReview(_course.id, {
                      'rating': rating,
                      'comment': commentCtrl.text,
                    });
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    _fetchDetails(); // refresh reviews
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!')));
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _enroll() async {
    setState(() => _isEnrolling = true);
    final provider = context.read<CourseProvider>();
    final success = await provider.enrollStudent(_course.id);
    if (!mounted) return;
    setState(() => _isEnrolling = false);

    if (success) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Enrollment Requested'),
          content: const Text('Your request has been sent to the instructor and is pending approval.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Enrollment failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_course.thumbnailUrl != null)
              Image.network(_course.thumbnailUrl!, height: 250, fit: BoxFit.cover)
            else
              Container(height: 250, color: Colors.grey.shade300, child: const Icon(Icons.image, size: 80, color: Colors.grey)),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_course.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_course.shortDescription, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700)),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoBadge(Icons.bar_chart, _course.level),
                      _buildInfoBadge(Icons.language, _course.language),
                      _buildInfoBadge(Icons.attach_money, _course.price > 0 ? '\$${_course.price}' : 'Free'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('About this Course', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_course.description, style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 24),

                  if (_course.learningOutcomes.isNotEmpty) ...[
                    const Text('What you will learn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._course.learningOutcomes.map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, size: 20, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(child: Text(o)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

                  if (_course.requirements.isNotEmpty) ...[
                    const Text('Requirements', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._course.requirements.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.circle, size: 8, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(child: Text(r)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

                  const Text('Curriculum Preview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_course.sections.isEmpty)
                    const Text('Curriculum not available yet.')
                  else
                    ..._course.sections.map((section) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          children: section.lessons.map((lesson) {
                            return ListTile(
                              leading: Icon(
                                lesson.lessonType == 'VIDEO' ? Icons.play_circle :
                                lesson.lessonType == 'DOCUMENT' ? Icons.picture_as_pdf :
                                Icons.text_snippet,
                              ),
                              title: Text(lesson.title),
                              trailing: lesson.isPreview ? const Text('Preview', style: TextStyle(color: Colors.blue)) : const Icon(Icons.lock, size: 16),
                            );
                          }).toList(),
                        ),
                      );
                    }),
                  const SizedBox(height: 32),
                  
                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _showReviewDialog,
                        icon: const Icon(Icons.edit),
                        label: const Text('Write a Review'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_reviews.isEmpty)
                    const Text('No reviews yet. Be the first to review!')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        // Filter out hidden reviews for non-instructors
                        if (review.isHidden) return const SizedBox.shrink(); 
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(review.studentName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    Row(
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          starIndex < review.rating ? Icons.star : Icons.star_border,
                                          size: 16,
                                          color: Colors.amber,
                                        );
                                      }),
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
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: _isEnrolling ? null : _enroll,
            child: _isEnrolling ? const CircularProgressIndicator(color: Colors.white) : const Text('Enroll Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade700),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
