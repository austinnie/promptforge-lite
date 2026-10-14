import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

import '../core/app_config.dart';
import '../providers/config_provider.dart';

class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({super.key});

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage> {
  List<_GalleryItem> _images = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    // 监听配置变化，配置变更后刷新列表
    ref.listen<ConfigNotifier>(configProvider, (_, __) {
      _load();
    });
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
      
      final items = await Future.wait(
        files.map((f) async {
          final prompt = await _readPrompt(f);
          return _GalleryItem(file: f, prompt: prompt);
        }),
      );
      
      if (!mounted) return;
      setState(() {
        _images = items;
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

  Future<void> _delete(_GalleryItem item) async {
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
      await item.file.delete();
      final meta = File(item.file.path.replaceAll('.png', '.json'));
      if (meta.existsSync()) await meta.delete();
    } catch (_) {}
    _load();
  }

  void _openViewer(_GalleryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ViewerPage(
          image: item.file,
          prompt: item.prompt,
        ),
      ),
    );
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '还没有作品\n去「生成」里创作吧',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
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
                      final item = _images[i];
                      return GestureDetector(
                        onTap: () => _openViewer(item),
                        onLongPress: () => _delete(item),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(item.file, fit: BoxFit.cover),
                            ),
                            if (item.prompt != null)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.7),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Text(
                                    item.prompt!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _GalleryItem {
  final File file;
  final String? prompt;

  const _GalleryItem({required this.file, this.prompt});
}

class _ViewerPage extends StatelessWidget {
  final File image;
  final String? prompt;

  const _ViewerPage({required this.image, this.prompt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(prompt ?? image.path.split('/').last),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(image, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
