// lib/pages/home/home_page.dart
import 'package:flutter/material.dart';

import '../create/create_page.dart';
import '../gallery/gallery_page.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _pages = <Widget>[
    CreatePage(),
    GalleryPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PromptForge Lite'),
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome),
            label: '生成',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library),
            label: '作品',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune),
            label: '设置',
          ),
        ],
      ),
    );
  }
}