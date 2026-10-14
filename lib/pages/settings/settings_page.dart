import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/config_provider.dart';
import '../services/agnes_direct.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);
    final isTesting = ref.watch(_testingProvider);
    
    return _SettingsContent(
      config: config,
      isTesting: isTesting,
      onTest: () => _testConnection(context, ref),
      onSave: () => _saveConfig(ref),
    );
  }

  Future<void> _testConnection(BuildContext context, WidgetRef ref) async {
    ref.read(_testingProvider.notifier).state = true;
    final ok = await AgnesDirect(ref.read(agnesConfigProvider)).ping();
    ref.read(_testingProvider.notifier).state = false;
    
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '✅ 连接成功' : '❌ 连接失败，请检查 API Key'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _saveConfig(WidgetRef ref) async {
    await ref.read(configProvider.notifier).save();
    if (!ref.context.mounted) return;
    ScaffoldMessenger.of(ref.context).showSnackBar(
      const SnackBar(content: Text('已保存')),
    );
  }
}

final _testingProvider = StateProvider<bool>((ref) => false);

class _SettingsContent extends StatefulWidget {
  final ConfigNotifier config;
  final bool isTesting;
  final VoidCallback onTest;
  final VoidCallback onSave;

  const _SettingsContent({
    required this.config,
    required this.isTesting,
    required this.onTest,
    required this.onSave,
  });

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent> {
  late final _keyCtrl = TextEditingController(text: widget.config.apiKey);
  late final _urlCtrl = TextEditingController(text: widget.config.baseUrl);
  late final _modelCtrl = TextEditingController(text: widget.config.imageModel);

  @override
  void dispose() {
    _keyCtrl.dispose();
    _urlCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            hintText: 'https://apihub.agnes-ai.com/v1',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _modelCtrl,
          decoration: const InputDecoration(
            labelText: '图像模型',
            hintText: 'agnes-image-2.1-flash',
            prefixIcon: Icon(Icons.memory),
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.isTesting ? null : widget.onTest,
                icon: widget.isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering),
                label: Text(widget.isTesting ? '测试中…' : '保存并测试'),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: widget.isTesting ? null : widget.onSave,
              child: const Text('仅保存'),
            ),
          ],
        ),

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
