import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/agnes_config.dart';

class ConfigNotifier extends ChangeNotifier {
  String _apiKey = '';
  String _baseUrl = AgnesConfig.defaultBaseUrl;
  String _imageModel = AgnesConfig.defaultImageModel;

  String get apiKey => _apiKey;
  String get baseUrl => _baseUrl;
  String get imageModel => _imageModel;
  bool get isReady => _apiKey.isNotEmpty;

  ConfigNotifier();

  void setValues({
    required String apiKey,
    required String baseUrl,
    required String imageModel,
  }) {
    _apiKey = apiKey;
    _baseUrl = baseUrl;
    _imageModel = imageModel;
    notifyListeners();
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('agnes_api_key', _apiKey);
    await sp.setString('agnes_base_url', _baseUrl);
    await sp.setString('agnes_image_model', _imageModel);
  }

  static Future<ConfigNotifier> load() async {
    final sp = await SharedPreferences.getInstance();
    final notifier = ConfigNotifier();
    notifier._apiKey = sp.getString('agnes_api_key') ?? '';
    notifier._baseUrl =
        sp.getString('agnes_base_url') ?? AgnesConfig.defaultBaseUrl;
    notifier._imageModel =
        sp.getString('agnes_image_model') ?? AgnesConfig.defaultImageModel;
    return notifier;
  }
}

final configProvider = ChangeNotifierProvider<ConfigNotifier>((ref) {
  return ConfigNotifier();
});

final agnesConfigProvider = Provider<AgnesConfig>((ref) {
  final cfg = ref.watch(configProvider);
  return AgnesConfig(
    apiKey: cfg.apiKey,
    baseUrl: cfg.baseUrl,
    imageModel: cfg.imageModel,
  );
});
