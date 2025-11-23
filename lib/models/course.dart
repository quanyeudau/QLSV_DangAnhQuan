class Course {
  String id;
  String name;
  int credits;
  String? instructor;
  String? scheduleCode; // simple code representing schedule

  Course({required this.id, required this.name, required this.credits, this.instructor, this.scheduleCode});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'credits': credits,
        'instructor': instructor,
        'schedule_code': scheduleCode,
      };

  factory Course.fromMap(Map<String, dynamic> m) => Course(
        id: m['id'] as String,
        name: m['name'] as String,
        credits: (m['credits'] is int) ? m['credits'] as int : int.parse(m['credits'].toString()),
        instructor: m['instructor'] as String?,
        scheduleCode: m['schedule_code'] as String?,
      );
}
