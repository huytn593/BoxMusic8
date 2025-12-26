import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../data/repositories/repository.dart';
import '../../widgets/app_page.dart';
import '../auth/controllers/auth_controller.dart';

class UploadTrackScreen extends ConsumerStatefulWidget {
  const UploadTrackScreen({super.key});

  @override
  ConsumerState<UploadTrackScreen> createState() => _UploadTrackScreenState();
}

class _UploadTrackScreenState extends ConsumerState<UploadTrackScreen> {
  final _titleController = TextEditingController();
  final _albumController = TextEditingController();
  final _genresController = TextEditingController();
  File? _audioFile;
  File? _coverFile;
  String? _coverBase64;
  bool _uploading = false;
  String? _message;
  bool _isPublic = true; // Mặc định: nhạc thường (true = public, false = VIP)

  @override
  void dispose() {
    _titleController.dispose();
    _albumController.dispose();
    _genresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).session;
    
    // Tất cả user đã đăng nhập đều có thể upload (match React frontend)
    if (session == null) {
      return const AppPage(
        title: 'Tải nhạc',
        child: Center(
          child: Text('Vui lòng đăng nhập để tải nhạc lên.'),
        ),
      );
    }

    return AppPage(
      title: 'Tải bài hát mới',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Tên bài hát'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _albumController,
              decoration: const InputDecoration(labelText: 'Album (tuỳ chọn)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _genresController,
              decoration: const InputDecoration(labelText: 'Thể loại (phân tách bằng dấu phẩy)'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Chọn file âm thanh'),
              subtitle: Text(_audioFile?.path ?? 'Chưa chọn'),
              trailing: IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: _pickAudio,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ảnh bìa (tuỳ chọn)'),
              subtitle: Text(_coverFile?.path ?? 'Chưa chọn'),
              trailing: IconButton(
                icon: const Icon(Icons.image),
                onPressed: _pickCover,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Loại nhạc',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<bool>(
                      title: const Text('Nhạc thường (Công khai)'),
                      subtitle: const Text('Tất cả người dùng đều có thể nghe'),
                      value: true,
                      groupValue: _isPublic,
                      onChanged: (value) => setState(() => _isPublic = value ?? true),
                    ),
                    // Chỉ admin mới thấy option "Nhạc VIP"
                    if (session.isAdmin)
                    RadioListTile<bool>(
                      title: const Row(
                        children: [
                          Text('Nhạc VIP'),
                          SizedBox(width: 8),
                          Icon(Icons.workspace_premium, size: 18, color: Colors.amber),
                        ],
                      ),
                        subtitle: const Text('Chỉ VIP, Premium mới nghe được'),
                      value: false,
                      groupValue: _isPublic,
                      onChanged: (value) => setState(() => _isPublic = value ?? false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(
                  color: _message!.startsWith('Thành công') ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploading ? null : _submit,
                child: _uploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tải lên'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _audioFile = File(result.files.single.path!));
    }
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      try {
        final base64 = await _encodeCover(file);
        if (!mounted) return;
        setState(() {
          _coverFile = file;
          _coverBase64 = base64;
        });
      } catch (error) {
        setState(() => _message = 'Không thể đọc ảnh bìa: $error');
      }
    }
  }

  Future<void> _submit() async {
    final session = ref.read(authControllerProvider).session;
    if (session == null) {
      setState(() => _message = 'Phiên đăng nhập đã hết hạn.');
      return;
    }
    if (_audioFile == null || _titleController.text.isEmpty) {
      setState(() => _message = 'Vui lòng nhập đầy đủ thông tin và chọn file.');
      return;
    }
    setState(() {
      _uploading = true;
      _message = null;
    });
    try {
      final repository = ref.read(repositoryProvider);
      final isAdmin = session.isAdmin;
      // User thường chỉ có thể upload nhạc thường (isPublic = true)
      // Chỉ admin mới có thể set VIP, nhưng backend không nhận isPublic khi upload
      // Admin sẽ set VIP sau khi upload qua màn hình quản lý
      final payload = UploadTrackPayload(
        title: _titleController.text,
        filePath: _audioFile!.path,
        album: _albumController.text.isEmpty ? null : _albumController.text,
        genres: _parseGenres(),
        artistId: isAdmin ? null : session.id,
        coverBase64: _coverBase64,
        isPublic: isAdmin ? _isPublic : true, // User thường luôn upload nhạc thường
      );
      final uploadedTitle = _titleController.text.trim();
      await repository.uploadTrack(payload);
      final successMessage = isAdmin
          ? 'Thành công! Bài hát đã sẵn sàng.'
          : 'Thành công! Bài hát đang chờ duyệt.';
      setState(() {
        _message = successMessage;
        _audioFile = null;
        _coverFile = null;
        _coverBase64 = null;
        _titleController.clear();
        _albumController.clear();
        _genresController.clear();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          action: SnackBarAction(
            label: 'Tìm kiếm',
            onPressed: () {
              if (uploadedTitle.isNotEmpty) {
                context.go('/search?q=${Uri.encodeComponent(uploadedTitle)}');
              }
            },
          ),
        ),
      );
    } catch (error) {
      setState(() => _message = 'Không thể tải lên: $error');
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  List<String> _parseGenres() {
    return _genresController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<String> _encodeCover(File file) async {
    final bytes = await file.readAsBytes();
    final mime = _detectMimeType(file.path);
    final data = base64Encode(bytes);
    return 'data:$mime;base64,$data';
  }

  String _detectMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}

