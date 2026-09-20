// lib/pages/gallery/gallery_page.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/app_config.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<File> _images = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final galleryDir = Directory('${dir.path}/${AppConfig.galleryDirName}');
      if (!galleryDir.existsSync()) {
        if (!mounted) return;
        setState(() {
          _images = [];
          _loading = false;
        });
        return;
      }
      final files = galleryDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.png'))
          .toList();
      files.sort((a, b) => b.path.compareTo(a.path));
      if (!mounted) return;
      setState(() {
        _images = files;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<String?> _readPrompt(File img) async {
    try {
      final meta = File(img.path.replaceAll('.png', '.json'));
      if (!meta.existsSync()) return null;
      final data = jsonDecode(await meta.readAsString()) as Map<String, dynamic>;
      return data['prompt']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _delete(File img) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除？'),
        content: const Text('无法恢复'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await img.delete();
      final meta = File(img.path.replaceAll('.png', '.json'));
      if (meta.existsSync()) await meta.delete();
    } catch (_) {}
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('作品'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty
              ? const Center(
                  child: Text(
                    '还没有作品\n去「生成」里创作吧',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _images.length,
                    itemBuilder: (_, i) {
                      final img = _images[i];
                      return GestureDetector(
                        onTap: () => _openViewer(img),
                        onLongPress: () => _delete(img),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(img, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _openViewer(File img) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ViewerPage(image: img, readPrompt: _readPrompt),
      ),
    );
  }
}

class _ViewerPage extends StatefulWidget {
  final File image;
  final Future<String?> Function(File) readPrompt;

  const _ViewerPage({required this.image, required this.readPrompt});

  @override
  State<_ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<_ViewerPage> {
  String? _prompt;

  @override
  void initState() {
    super.initState();
    widget.readPrompt(widget.image).then((p) {
      if (mounted) setState(() => _prompt = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_prompt ?? widget.image.path.split('/').last),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(widget.image, fit: BoxFit.contain),
        ),
      ),
    );
  }
}