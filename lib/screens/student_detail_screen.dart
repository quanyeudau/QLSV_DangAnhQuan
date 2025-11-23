import 'package:flutter/material.dart';
import '../models/student.dart';
import '../data/student_db.dart';

class StudentDetailScreen extends StatefulWidget {
	final Student? student; // null -> tạo mới
	const StudentDetailScreen({super.key, this.student});

	@override
	State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
	late final TextEditingController idController;
	late final TextEditingController nameController;
	late final TextEditingController scoreController;
	late final TextEditingController _avatarController;
	late final TextEditingController _emailController;
	late final TextEditingController _phoneController;
	late final TextEditingController _classController;
	late final TextEditingController _dobController;
	late final TextEditingController _addressController;
	bool _saving = false;
	bool _isNew = true;

	@override
	void initState() {
		super.initState();
		_isNew = widget.student == null;
		idController = TextEditingController(text: widget.student?.id ?? '');
		nameController = TextEditingController(text: widget.student?.name ?? '');
		scoreController = TextEditingController(text: widget.student?.score.toString() ?? '');
		_avatarController = TextEditingController(text: widget.student?.avatarUrl ?? '');
		_emailController = TextEditingController(text: widget.student?.email ?? '');
		_phoneController = TextEditingController(text: widget.student?.phone ?? '');
		_classController = TextEditingController(text: widget.student?.className ?? '');
		_dobController = TextEditingController(text: widget.student?.dob ?? '');
		_addressController = TextEditingController(text: widget.student?.address ?? '');
	}

	@override
	void dispose() {
		idController.dispose();
		nameController.dispose();
		scoreController.dispose();
		_avatarController.dispose();
		_emailController.dispose();
		_phoneController.dispose();
		_classController.dispose();
		_dobController.dispose();
		_addressController.dispose();
		super.dispose();
	}

	Future<void> _save() async {
		final id = idController.text.trim();
		final name = nameController.text.trim();
		final score = double.tryParse(scoreController.text) ?? 0;
		final avatar = _avatarController.text.trim();
		final email = _emailController.text.trim();
		final phone = _phoneController.text.trim();
		final className = _classController.text.trim();
		final dob = _dobController.text.trim();
		final address = _addressController.text.trim();
		if (id.isEmpty || name.isEmpty) {
			if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã và tên không được trống')));
			return;
		}
		if (score < 0 || score > 10) {
			if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Điểm phải trong khoảng 0-10')));
			return;
		}
		setState(() => _saving = true);
		try {
			final student = Student(
				id: id,
				name: name,
				score: score,
				avatarUrl: avatar.isEmpty ? null : avatar,
				email: email.isEmpty ? null : email,
				phone: phone.isEmpty ? null : phone,
				className: className.isEmpty ? null : className,
				dob: dob.isEmpty ? null : dob,
				address: address.isEmpty ? null : address,
			);
			await StudentDb.instance.upsertStudent(student);
			if (mounted) Navigator.of(context).pop(true);
		} catch (e) {
			if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lưu: $e')));
		} finally {
			if (mounted) setState(() => _saving = false);
		}
	}

	Future<void> _delete() async {
		if (_isNew || widget.student == null) return;
		final confirm = await showDialog<bool>(
			context: context,
			builder: (_) => AlertDialog(
				title: const Text('Xác nhận xoá'),
				content: Text('Xoá sinh viên ${widget.student!.name}?'),
				actions: [
					TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
					ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
				],
			),
		);
		if (confirm != true) return;
		try {
			await StudentDb.instance.deleteStudent(widget.student!.id);
			if (mounted) Navigator.of(context).pop(true);
		} catch (e) {
			if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xoá: $e')));
		}
	}

	@override
	Widget build(BuildContext context) {
		final rank = !_isNew ? widget.student!.getRank() : null;
			return Scaffold(
			appBar: AppBar(
				title: Text(_isNew ? 'Thêm sinh viên' : 'Chi tiết sinh viên'),
				actions: [
					if (!_isNew)
						IconButton(
							icon: const Icon(Icons.delete_outline),
							tooltip: 'Xoá',
							onPressed: _delete,
						)
				],
			),
			body: SingleChildScrollView(
				padding: const EdgeInsets.all(20),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						Card(
							child: Padding(
								padding: const EdgeInsets.all(16),
								child: Column(
									children: [
										TextField(
											controller: idController,
											enabled: _isNew,
											decoration: const InputDecoration(labelText: 'Mã SV'),
										),
										const SizedBox(height: 12),
										TextField(
											controller: nameController,
											decoration: const InputDecoration(labelText: 'Tên SV'),
										),
										const SizedBox(height: 12),
										TextField(
											controller: scoreController,
											keyboardType: const TextInputType.numberWithOptions(decimal: true),
											decoration: const InputDecoration(labelText: 'Điểm (0-10)'),
										),
										const SizedBox(height: 12),
										TextField(
											controller: _avatarController,
											decoration: const InputDecoration(labelText: 'Avatar URL (tuỳ chọn)'),
										),
										const SizedBox(height: 12),
										TextField(
											controller: _emailController,
											keyboardType: TextInputType.emailAddress,
											decoration: const InputDecoration(labelText: 'Email (tuỳ chọn)'),
										),
										const SizedBox(height: 12),
										TextField(
											controller: _phoneController,
											keyboardType: TextInputType.phone,
											decoration: const InputDecoration(labelText: 'Số điện thoại (tuỳ chọn)'),
										),
										const SizedBox(height: 12),
										TextField(
											controller: _classController,
											decoration: const InputDecoration(labelText: 'Lớp / Khoa (tuỳ chọn)'),
										),
										const SizedBox(height: 12),
										TextField(
											controller: _dobController,
											decoration: const InputDecoration(labelText: 'Ngày sinh (YYYY-MM-DD)'),
										),
										const SizedBox(height: 12),
										TextField(
											controller: _addressController,
											maxLines: 2,
											decoration: const InputDecoration(labelText: 'Địa chỉ (tuỳ chọn)'),
										),
										if (_avatarController.text.isNotEmpty) ...[
											const SizedBox(height: 8),
											Align(
												alignment: Alignment.centerLeft,
												child: CircleAvatar(
													radius: 30,
													backgroundImage: NetworkImage(_avatarController.text),
												),
											),
										],
										if (rank != null) ...[
											const SizedBox(height: 12),
											Align(
												alignment: Alignment.centerLeft,
												child: Chip(label: Text('Xếp loại: $rank')), 
											),
										],
									],
								),
							),
						),
						const SizedBox(height: 20),
						ElevatedButton.icon(
							onPressed: _saving ? null : _save,
							icon: const Icon(Icons.save_rounded),
							label: Text(_isNew ? 'Thêm mới' : 'Lưu thay đổi'),
						),
					],
				),
			),
		);
	}
}

