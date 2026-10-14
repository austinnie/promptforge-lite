import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

import '../core/app_config.dart';
import '../providers/config_provider.dart';
import '../providers/generation_provider.dart';

enum _Mode { text2img, img2img }

class CreatePage extends ConsumerWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);
    final generation = ref.watch(generationProvider);
    
    return _CreatePageContent(
      config: config,
      generation: generation,
    );
  }
}

class _CreatePageContent extends StatefulWidget {
  final ConfigNotifier config;
  final GenerationNotifier generation;

  const _CreatePageContent({
    required this.config,
    required this.generation,
  });

  @override
  State<_CreatePageContent> createState() => _CreatePageContentState();
}

class _CreatePageContentState extends State<_CreatePageContent> {
  final _promptCtrl = TextEditingController();
  int _width = 1024;
  int _height = 1024;
  _Mode _mode = _Mode.text2img;

  Uint8List? _refBytes;
  String? _refName;
  double _strength = 0.7;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRef() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1536,
        maxHeight: 1536,
        imageQuality: 90,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() {
        _refBytes = bytes;
        _refName = x.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败: $e')),
      );
    }
  }

  void _clearRef() {
    setState(() {
      _refBytes = null;
      _refName = null;
    });
  }

  Future<void> _submit() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入描述')),
      );
      return;
    }
    if (_mode == _Mode.img2img && _refBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择参考图')),
      );
      return;
    }
    if (!widget.config.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先到「设置」里填写 API Key')),
      );
      return;
    }

    try {
      if (kIsWeb) {
        if (_mode == _Mode.img2img) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Web 端暂不支持图生图，请在手机/桌面端使用'),
            ),
          );
          return;
        }
        await widget.generation.generateImageUrl(
          prompt: prompt,
          width: _width,
          height: _height,
          config: widget.config,
        );
        if (mounted) _promptCtrl.clear();
        return;
      }

      if (_mode == _Mode.text2img) {
        await widget.generation.generateTextToImage(
          prompt: prompt,
          width: _width,
          height: _height,
          config: widget.config,
        );
      } else {
        await widget.generation.generateImageToImage(
          prompt: prompt,
          imageBytes: _refBytes!,
          strength: _strength,
          width: _width,
          height: _height,
          config: widget.config,
        );
      }
      if (mounted) _promptCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final generation = widget.generation;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---- 模式切换 ----
        SegmentedButton<_Mode>(
          segments: const [
            ButtonSegment(
              value: _Mode.text2img,
              icon: Icon(Icons.text_fields),
              label: Text('文生图'),
            ),
            ButtonSegment(
              value: _Mode.img2img,
              icon: Icon(Icons.image),
              label: Text('图生图'),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (s) {
            setState(() => _mode = s.first);
          },
        ),

        const SizedBox(height: 16),

        // ---- 参考图（仅图生图模式）----
        if (_mode == _Mode.img2img) ...[
          if (kIsWeb)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Web 端可选图预览，但提交图生图会被拦截。请用手机端跑图生图。',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _refBytes == null
                  ? Row(
                      children: [
                        const Icon(Icons.image_outlined, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('选择参考图（用于图生图）')),
                        FilledButton.tonal(
                          onPressed: _pickRef,
                          child: const Text('选择'),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            _refBytes!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _refName ?? '参考图',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(_refBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: _pickRef,
                                    child: const Text('换一张'),
                                  ),
                                  TextButton(
                                    onPressed: _clearRef,
                                    child: const Text('清除'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                const Text('强度：'),
                Expanded(
                  child: Slider(
                    value: _strength,
                    min: 0.1,
                    max: 1.0,
                    divisions: 18,
                    label: _strength.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _strength = v),
                  ),
                ),
                Text(_strength.toStringAsFixed(2)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ---- 描述 ----
        TextField(
          controller: _promptCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: '描述',
            hintText: _mode == _Mode.text2img
                ? '例如：月光下的森林，一只白鹿站在溪边'
                : '例如：改成梵高油画风格，星空旋转',
          ),
        ),
        const SizedBox(height: 12),

        // ---- 尺寸 ----
        Row(
          children: [
            const Text('尺寸：'),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _width,
              items: AppConfig.sizeOptions
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
              onChanged: (v) => setState(() => _width = v ?? 1024),
            ),
            const Text(' × '),
            DropdownButton<int>(
              value: _height,
              items: AppConfig.sizeOptions
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
              onChanged: (v) => setState(() => _height = v ?? 1024),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ---- 提交按钮 ----
        FilledButton.icon(
          onPressed: generation.state == GenerationState.loading ? null : _submit,
          icon: generation.state == GenerationState.loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(
            generation.state == GenerationState.loading ? '生成中…' : '提交生成',
          ),
        ),

        const SizedBox(height: 16),

        // ---- 加载状态提示 ----
        if (generation.state == GenerationState.loading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '正在生成图片，请稍候……',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

        // ---- 结果展示 ----
        if (generation.lastResult != null && generation.state != GenerationState.loading) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        '生成完成',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    generation.lastResult!.prompt,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: generation.lastResult!.url != null
                        ? _SafeNetworkImage(url: generation.lastResult!.url!)
                        : generation.lastResult!.localPath != null
                            ? Image.file(
                                File(generation.lastResult!.localPath!),
                                fit: BoxFit.contain,
                              )
                            : const SizedBox(
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        '${generation.lastResult!.width} × ${generation.lastResult!.height}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        generation.lastResult!.timestamp.toString().substring(0, 16),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],

        if (generation.state == GenerationState.error) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '生成失败，请稍后重试',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 安全的网络图片组件，避免 inactive element 断言错误
class _SafeNetworkImage extends StatefulWidget {
  final String url;

  const _SafeNetworkImage({required this.url});

  @override
  State<_SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<_SafeNetworkImage> {
  bool _loaded = false;
  bool _error = false;

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image, color: Colors.grey, size: 40),
              SizedBox(height: 8),
              Text('图片加载失败', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    return Image.network(
      widget.url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          if (!mounted) return child;
          setState(() => _loaded = true);
          return child;
        }
        if (!mounted) return const SizedBox.shrink();
        return Center(
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        if (!mounted) return const SizedBox.shrink();
        setState(() => _error = true);
        return const SizedBox.shrink();
      },
    );
  }
}
