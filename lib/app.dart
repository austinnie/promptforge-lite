// lib/app.dart
import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'pages/home/home_page.dart';

class PromptForgeLiteApp extends StatelessWidget {
  const PromptForgeLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PromptForge Lite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomePage(),
    );
  }
}