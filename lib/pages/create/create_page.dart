// lib/pages/create/create_page.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/app_config.dart';
import '../../services/agnes_config.dart';
import '../../services/agnes_direct.dart';

enum _Mode { text2img, img2img }

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final _promptCtrl = TextEditingController();
  int _width = 1024;
  int _height = 1024;
  _Mode _mode = _Mode.text2img;

  // 图生图
  Uint8List? _refBytes;
  String? _refName;
  double _strength = 0.7;

  bool _busy = false;
  String? _msg;
  String? _resultPath;
  String? _resultUrl;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRef() async {
    try {
      final x = await _picker.pickImage(
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
        _msg = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _msg = '选择图片失败: $e');
    }
  }

  Future<void> _submit() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      setState(() => _msg = '请输入描述');
      return;
    }
    if (_mode == _Mode.img2img && _refBytes == null) {
      setState(() => _msg = '请先选择参考图');
      return;
    }

    final cfg = await AgnesConfig.load();
    if (!cfg.isReady) {
      setState(() => _msg = '请先到「设置」里填 Agnes API Key');
      return;
    }

    setState(() {
      _busy = true;
      _msg = null;
      _resultPath = null;
      _resultUrl = null;
    });

    try {
      final client = AgnesDirect(cfg);

      if (kIsWeb) {
        // Web：只拿 URL，不下载（避开 CORS）
        if (_mode == _Mode.img2img) {
          throw Exception('Web 端暂不支持图生图，请在手机/桌面端使用');
        }
        final url = await client.generateImageUrl(
          prompt: prompt,
          width: _width,
          height: _height,
        );
        if (!mounted) return;
        setState(() {
          _busy = false;
          _msg = '生成完成';
          _resultUrl = url;
        });
        _promptCtrl.clear();
        return;
      }

      // 非 Web：下载字节 + 存本地
      final Uint8List bytes;
      if (_mode == _Mode.text2img) {
        bytes = await client.generateImage(
          prompt: prompt,
          width: _width,
          height: _height,
        );
      } else {
        bytes = await client.imageToImage(
          prompt: prompt,
          imageBytes: _refBytes!,
          strength: _strength,
          width: _width,
          height: _height,
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final galleryDir = Directory('${dir.path}/${AppConfig.galleryDirName}');
      if (!galleryDir.existsSync()) {
        galleryDir.createSync(recursive: true);
      }
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${galleryDir.path}/$ts.png');
      await file.writeAsBytes(bytes);

      final metaFile = File('${galleryDir.path}/$ts.json');
      await metaFile.writeAsString(
        '{"prompt":"${prompt.replaceAll('"', r'\"')}","width":$_width,"height":$_height,"mode":"${_mode.name}","ts":$ts}',
      );

      if (!mounted) return;
      setState(() {
        _busy = false;
        _msg = '生成完成';
        _resultPath = file.path;
      });
      _promptCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _msg = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 模式切换
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
            setState(() {
              _mode = s.first;
              _msg = null;
            });
          },
        ),

        const SizedBox(height: 16),

        // 参考图（仅图生图）
        if (_mode == _Mode.img2img) ...[
          _RefCard(
            bytes: _refBytes,
            name: _refName,
            onPick: _pickRef,
            onClear: () => setState(() {
              _refBytes = null;
              _refName = null;
            }),
          ),
          const SizedBox(height: 12),
          Row(
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
          const SizedBox(height: 12),
        ],

        // 描述
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

        // 尺寸
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

        // 提交
        FilledButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(_busy ? '生成中…' : '提交生成'),
        ),

        if (_msg != null) ...[
          const SizedBox(height: 12),
          Text(
            _msg!,
            style: TextStyle(
              color: _msg == '生成完成' ? Colors.green : Colors.red,
            ),
          ),
        ],

        if (_resultPath != null || _resultUrl != null) ...[
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '生成结果',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _resultUrl != null
                        ? Image.network(_resultUrl!, fit: BoxFit.contain)
                        : Image.file(
                            File(_resultPath!),
                            fit: BoxFit.contain,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RefCard extends StatelessWidget {
  final Uint8List? bytes;
  final String? name;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _RefCard({
    required this.bytes,
    required this.name,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (bytes == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.image_outlined),
          title: const Text('选择参考图'),
          trailing: FilledButton.tonal(
            onPressed: onPick,
            child: const Text('选择'),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(
                bytes!,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? '参考图',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(bytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      TextButton(onPressed: onPick, child: const Text('换一张')),
                      TextButton(onPressed: onClear, child: const Text('清除')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}