import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/config_provider.dart';
import 'pages/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化配置
  final configNotifier = await ConfigNotifier.load();
  
  runApp(
    ProviderScope(
      overrides: [
        configProvider.overrideWithValue(configNotifier),
      ],
      child: const PromptForgeLiteApp(),
    ),
  );
}

class PromptForgeLiteApp extends ConsumerWidget {
  const PromptForgeLiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'PromptForge Lite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
