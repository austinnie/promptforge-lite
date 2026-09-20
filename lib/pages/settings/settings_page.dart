// lib/pages/settings/settings_page.dart
import 'package:flutter/material.dart';

import '../../services/agnes_config.dart';
import '../../services/agnes_direct.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _keyCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();

  bool _loading = true;
  bool _testing = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await AgnesConfig.load();
    if (!mounted) return;
    setState(() {
      _keyCtrl.text = c.apiKey;
      _urlCtrl.text = c.baseUrl;
      _modelCtrl.text = c.imageModel;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final c = AgnesConfig(
      apiKey: _keyCtrl.text.trim(),
      baseUrl: _urlCtrl.text.trim().isEmpty
          ? AgnesConfig.defaultBaseUrl
          : _urlCtrl.text.trim(),
      imageModel: _modelCtrl.text.trim().isEmpty
          ? AgnesConfig.defaultImageModel
          : _modelCtrl.text.trim(),
    );
    await c.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存')),
    );
    setState(() => _status = null);
  }

  Future<void> _test() async {
    // 先保存再测
    await _save();
    final c = await AgnesConfig.load();
    if (!mounted) return;
    setState(() {
      _testing = true;
      _status = null;
    });

    final ok = await AgnesDirect(c).ping();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _status = ok ? '✅ Key 有效' : '❌ 连接失败，请检查 key / base_url';
    });
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _urlCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Agnes 配置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          '填入你自己的 Agnes API Key，App 会直接调用 Agnes 生图。',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _keyCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'API Key',
            hintText: 'sk-...',
            prefixIcon: Icon(Icons.vpn_key),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _urlCtrl,
          decoration: const InputDecoration(
            labelText: 'Base URL',
            hintText: AgnesConfig.defaultBaseUrl,
            prefixIcon: Icon(Icons.link),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _modelCtrl,
          decoration: const InputDecoration(
            labelText: '图像模型',
            hintText: AgnesConfig.defaultImageModel,
            prefixIcon: Icon(Icons.memory),
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _testing ? null : _test,
                icon: _testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering),
                label: Text(_testing ? '测试中…' : '保存并测试'),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _testing ? null : _save,
              child: const Text('仅保存'),
            ),
          ],
        ),

        if (_status != null) ...[
          const SizedBox(height: 16),
          Text(
            _status!,
            style: TextStyle(
              fontSize: 14,
              color: _status!.startsWith('✅') ? Colors.green : Colors.red,
            ),
          ),
        ],

        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          '关于',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('PromptForge Lite v0.1.0', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        const Text(
          '直连 Agnes，无需后端。',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }
}