class Student {
  String id;
  String name;
  double score;
  String? avatarUrl; // optional remote/local image URL

  Student({required this.id, required this.name, required this.score, this.avatarUrl});

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
      'avatar_url': avatarUrl,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      name: map['name'] as String,
      score: (map['score'] is int) ? (map['score'] as int).toDouble() : map['score'] as double,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  // Generate a deterministic color based on id for placeholder avatar background
  int get avatarColorValue {
    final hash = id.codeUnits.fold(0, (p, c) => p + c);
    // keep within nice pastel range by mixing with a base
    final r = (100 + (hash * 37) % 156);
    final g = (100 + (hash * 53) % 156);
    final b = (100 + (hash * 61) % 156);
    return (0xFF << 24) | (r << 16) | (g << 8) | b;
  }
}
