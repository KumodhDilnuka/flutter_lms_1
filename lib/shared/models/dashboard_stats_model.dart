class DashboardStatsModel {
  final Map<String, dynamic> rawStats;

  DashboardStatsModel({required this.rawStats});

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(rawStats: json);
  }

  // Common getters for flexibility
  int get totalCourses => _getInt('totalCourses') ?? _getInt('coursesCount') ?? 0;
  int get totalStudents => _getInt('totalStudents') ?? _getInt('studentsCount') ?? 0;
  int get activeEnrollments => _getInt('activeEnrollments') ?? 0;
  int get completedCourses => _getInt('completedCourses') ?? 0;
  int get totalRevenue => _getInt('totalRevenue') ?? _getInt('revenue') ?? 0;
  int get totalInstructors => _getInt('totalInstructors') ?? 0;
  int get totalCategories => _getInt('totalCategories') ?? 0;

  // Helper to safely extract ints from strings or ints
  int? _getInt(String key) {
    if (!rawStats.containsKey(key)) return null;
    final val = rawStats[key];
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }
}
