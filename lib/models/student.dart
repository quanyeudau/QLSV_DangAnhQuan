class Student {
  String id;
  String name;
  double score;

  Student({required this.id, required this.name, required this.score});

  String getRank() {
    if (score >= 8) return 'Giỏi';
    if (score >= 6.5) return 'Khá';
    if (score >= 5) return 'Trung bình';
    return 'Yếu';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'score': score,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      name: map['name'] as String,
      score: (map['score'] is int) ? (map['score'] as int).toDouble() : map['score'] as double,
    );
  }
}
