// lib/core/app_config.dart

/// 全局常量配置。
class AppConfig {
  AppConfig._();

  /// HTTP 请求超时（生图可能慢，给 3 分钟）
  static const httpTimeout = Duration(seconds: 180);

  /// 下载图片超时
  static const downloadTimeout = Duration(seconds: 60);

  /// 默认支持的尺寸档位
  static const sizeOptions = [512, 768, 1024, 1280, 1536];

  /// 本地作品目录名
  static const galleryDirName = 'gallery';
}