import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'dart:io';

import '../services/agnes_config.dart';
import '../services/agnes_direct.dart';
import '../core/app_config.dart';

/// 生图任务状态
enum GenerationState { idle, loading, success, error }

/// 单次生成任务的结果数据
class GenerationResult {
  final String prompt;
  final Uint8List? bytes;
  final String? url;
  final String? localPath;
  final int width;
  final int height;
  final DateTime timestamp;
  final String? errorMessage;

  const GenerationResult({
    required this.prompt,
    this.bytes,
    this.url,
    this.localPath,
    required this.width,
    required this.height,
    required this.timestamp,
    this.errorMessage,
  });
}

class GenerationNotifier extends ChangeNotifier {
  GenerationState _state = GenerationState.idle;
  GenerationResult? _lastResult;
  List<GenerationResult> _history = [];

  GenerationState get state => _state;
  GenerationResult? get lastResult => _lastResult;
  List<GenerationResult> get history => _history;

  /// 执行文生图
  Future<void> generateTextToImage({
    required String prompt,
    required int width,
    required int height,
    required AgnesConfig config,
  }) async {
    _state = GenerationState.loading;
    notifyListeners();

    try {
      final client = AgnesDirect(config);
      final bytes = await client.generateImage(
        prompt: prompt,
        width: width,
        height: height,
      );

      // 保存到本地
      final dir = await _getGalleryDir();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/$ts.png');
      await file.writeAsBytes(bytes);

      final metaFile = File('${dir.path}/$ts.json');
      await metaFile.writeAsString(
        '{"prompt":"${prompt.replaceAll('"', r'\"')}","width":$width,"height":$height,"mode":"text2img","ts":$ts}',
      );

      final result = GenerationResult(
        prompt: prompt,
        bytes: bytes,
        localPath: file.path,
        width: width,
        height: height,
        timestamp: DateTime.now(),
      );

      _lastResult = result;
      _history.insert(0, result);
      _state = GenerationState.success;
    } catch (e) {
      _state = GenerationState.error;
      // ignore: avoid_print
      print('[Generation] Error: $e');
    } finally {
      notifyListeners();
    }
  }

  /// 执行图生图
  Future<void> generateImageToImage({
    required String prompt,
    required Uint8List imageBytes,
    required double strength,
    required int width,
    required int height,
    required AgnesConfig config,
  }) async {
    _state = GenerationState.loading;
    notifyListeners();

    try {
      final client = AgnesDirect(config);
      final bytes = await client.imageToImage(
        prompt: prompt,
        imageBytes: imageBytes,
        strength: strength,
        width: width,
        height: height,
      );

      final dir = await _getGalleryDir();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/$ts.png');
      await file.writeAsBytes(bytes);

      final metaFile = File('${dir.path}/$ts.json');
      await metaFile.writeAsString(
        '{"prompt":"${prompt.replaceAll('"', r'\"')}","strength":$strength,"width":$width,"height":$height,"mode":"img2img","ts":$ts}',
      );

      final result = GenerationResult(
        prompt: prompt,
        bytes: bytes,
        localPath: file.path,
        width: width,
        height: height,
        timestamp: DateTime.now(),
      );

      _lastResult = result;
      _history.insert(0, result);
      _state = GenerationState.success;
    } catch (e) {
      _state = GenerationState.error;
      // ignore: avoid_print
      print('[Generation] Error: $e');
    } finally {
      notifyListeners();
    }
  }

  /// 获取 Web 端的图片 URL（不下载）
  Future<String?> generateImageUrl({
    required String prompt,
    required int width,
    required int height,
    required AgnesConfig config,
  }) async {
    _state = GenerationState.loading;
    notifyListeners();

    try {
      final client = AgnesDirect(config);
      final url = await client.generateImageUrl(
        prompt: prompt,
        width: width,
        height: height,
      );

      final result = GenerationResult(
        prompt: prompt,
        url: url,
        width: width,
        height: height,
        timestamp: DateTime.now(),
      );

      _lastResult = result;
      _history.insert(0, result);
      _state = GenerationState.success;
      return url;
    } catch (e) {
      _state = GenerationState.error;
      // ignore: avoid_print
      print('[Generation] Error: $e');
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<Directory> _getGalleryDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final galleryDir = Directory('${dir.path}/${AppConfig.galleryDirName}');
    if (!galleryDir.existsSync()) {
      galleryDir.createSync(recursive: true);
    }
    return galleryDir;
  }

  void clearLastResult() {
    _lastResult = null;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
}

final generationProvider = ChangeNotifierProvider<GenerationNotifier>((ref) {
  return GenerationNotifier();
});
