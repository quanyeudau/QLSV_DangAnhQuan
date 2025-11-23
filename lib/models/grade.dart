class Grade {
  String studentId;
  String courseId;
  double? midterm;
  double? finalExam;
  double? total; // optional stored total

  Grade({required this.studentId, required this.courseId, this.midterm, this.finalExam, this.total});

  Map<String, dynamic> toMap() => {
        'student_id': studentId,
        'course_id': courseId,
        'midterm': midterm,
        'final': finalExam,
        'total': total,
      };

  factory Grade.fromMap(Map<String, dynamic> m) => Grade(
        studentId: m['student_id'] as String,
        courseId: m['course_id'] as String,
        midterm: m['midterm'] == null ? null : (m['midterm'] is int ? (m['midterm'] as int).toDouble() : m['midterm'] as double),
        finalExam: m['final'] == null ? null : (m['final'] is int ? (m['final'] as int).toDouble() : m['final'] as double),
        total: m['total'] == null ? null : (m['total'] is int ? (m['total'] as int).toDouble() : m['total'] as double),
      );

  /// Compute weighted total given weights (map with keys 'mid' and 'final').
  double computeWeighted(Map<String, double> weights) {
    final midW = weights['mid'] ?? 0.0;
    final finalW = weights['final'] ?? 0.0;
    final m = midterm ?? 0.0;
    final f = finalExam ?? 0.0;
    return m * midW + f * finalW;
  }
}
