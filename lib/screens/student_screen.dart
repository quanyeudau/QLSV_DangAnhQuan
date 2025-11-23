import 'package:flutter/material.dart';
import '../models/student.dart';
import '../data/student_db.dart';
import 'student_detail_screen.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final List<Student> _students = [];
  bool _loading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _rankFilter;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await StudentDb.instance.getAllStudents();
      if (!mounted) return;
      setState(() {
        _students
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Lỗi tải dữ liệu: $e';
        _loading = false;
      });
    }
  }

  List<Student> get _filtered {
    return _students.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery) ||
          s.id.toLowerCase().contains(_searchQuery);
      final rank = s.getRank();
      final matchesRank = _rankFilter == null || _rankFilter == rank;
      return matchesSearch && matchesRank;
    }).toList();
  }

  Future<void> _openAddStudent() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const StudentDetailScreen()),
    );
    if (changed == true) await _loadStudents();
  }

  Future<void> _openDetail(Student s) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => StudentDetailScreen(student: s)),
    );
    if (changed == true) await _loadStudents();
  }

  Future<void> _showDbPath() async {
    final path = await StudentDb.instance.getDbFilePath();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đường dẫn DB'),
        content: SelectableText(path),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sinh viên'),
        actions: [
          IconButton(onPressed: _showDbPath, icon: const Icon(Icons.info_outline)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddStudent,
        child: const Icon(Icons.person_add),
        tooltip: 'Thêm sinh viên',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc mã...',
                    prefixIcon: const Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _rankFilter == null,
                  onSelected: (_) => setState(() => _rankFilter = null),
                ),
                const SizedBox(width: 8),
                ...['Giỏi', 'Khá', 'Trung bình', 'Yếu'].map((r) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(r),
                        selected: _rankFilter == r,
                        onSelected: (sel) => setState(() => _rankFilter = sel ? r : null),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _filtered.isEmpty
                        ? const Center(child: Text('Không có sinh viên'))
                        : ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 0),
                            itemBuilder: (context, index) {
                              final s = _filtered[index];
                              final initials = s.name.isNotEmpty
                                  ? s.name.trim().split(' ').map((e) => e[0]).take(2).join()
                                  : s.id;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: scheme.primaryContainer,
                                  foregroundColor: scheme.onPrimaryContainer,
                                  child: Text(initials),
                                ),
                                title: Text(s.name),
                                subtitle: Text('${s.id} • Điểm: ${s.score} • ${s.getRank()}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openDetail(s),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
