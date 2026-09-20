# PromptForge Lite

> 直连 Agnes 的手机生图客户端 · 无需后端

一个用 Flutter 写的轻量级 AI 生图 App，直接调用 Agnes API 完成文生图 / 图生图，本地保存生成结果。

## 功能

- **文生图**：输入描述，直连 Agnes 生成
- **图生图**：从相册选参考图，调整强度后生成
- **本地图库**：生成结果保存在应用文档目录，带元数据（prompt / 尺寸 / 模式 / 时间戳）
- **配置面板**：API Key、Base URL、图像模型均可自定义
- **多路由 Fallback**：主域名失败时自动切换备用域名
- **无后端**：所有请求客户端直发 Agnes

## 平台支持

| 平台 | 文生图 | 图生图 | 说明 |
|------|:-----:|:-----:|------|
| Android | ✅ | ✅ | 完整支持 |
| iOS | ✅ | ✅ | 完整支持 |
| Windows / macOS / Linux | ✅ | ✅ | 完整支持 |
| **Web** | ✅ | ⚠️ | 图生图提交会被拦截 |

> **Web 端图生图限制**：Agnes 返回图片 URL 下载时会触发浏览器 CORS，代码中对 `kIsWeb` 做了拦截，提交会报 `Web 端暂不支持图生图，请在手机/桌面端使用`。Web 端仍可选图预览，只是不能提交。

## 环境要求

- Flutter SDK `>=3.3.0 <4.0.0`
- Dart `>=3.3.0`
- Android 构建需要 **JDK 17+**（Gradle 9 要求）

## 快速开始

```bash
# 1. 克隆
git clone <your-repo-url> promptforge-lite
cd promptforge-lite

# 2. 拉依赖
flutter pub get

# 3. 运行
flutter run -d <device>

# 例：
flutter run -d chrome               # Web 调试
flutter run -d windows              # Windows 桌面
flutter run -d <android-device-id>  # Android 真机
```

## 构建发布版

```bash
# Android APK
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk

# 安装到已连接设备
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Web
flutter build web --release
# 产物：build/web/
```

## 首次使用

APK 装好后是干净状态，需要先配置：

1. 打开 App → 底部「**设置**」
2. 填写：
   - **API Key**：你的 Agnes API Key
   - **Base URL**：默认 `https://apihub.agnes-ai.com/v1`
   - **图像模型**：默认 `agnes-image-2.1-flash`
3. 点「保存并测试」验证连通性
4. 回到「生成」页开始使用

> **API Key 保存在本地**（`shared_preferences`），不会上传到任何第三方。

## 目录结构

```
lib/
├── main.dart                       # 入口
├── app.dart                        # MaterialApp 配置
├── core/
│   ├── app_config.dart             # 尺寸选项、图库目录名等常量
│   └── theme.dart                  # 主题
├── pages/
│   ├── home/home_page.dart         # 底部导航（生成 / 作品 / 设置）
│   ├── create/create_page.dart     # 生成页（文生图 + 图生图）
│   ├── gallery/gallery_page.dart   # 本地图库
│   └── settings/settings_page.dart # Agnes 配置
└── services/
    ├── agnes_config.dart           # 配置读写 + 默认值 + fallback 路由
    └── agnes_direct.dart           # Agnes API 客户端
```

## Agnes API 调用

`lib/services/agnes_direct.dart` 封装两类请求：

- `generateImageUrl()` / `generateImage()` —— 文生图，`POST /images/generations`
- `imageToImage()` —— 图生图，请求体里带 `extra_body.image` 传 base64 参考图

多路由 fallback：主 `baseUrl` 失败时按 `AgnesConfig.fallbackRoutes` 顺序重试。

## 已知问题与修复记录

### Kotlin 增量编译跨盘崩溃

**现象**：`flutter build apk` 报

```
Could not close incremental caches
Suppressed: java.lang.IllegalArgumentException:
  this and base files have different roots:
  C:\Users\...\Pub\Cache\... and E:\...\android.
```

**原因**：Pub 缓存在 C 盘、项目在 E 盘，Kotlin 增量编译缓存处理跨盘路径失败。

**修复**：在 `android/gradle.properties` 加一行

```properties
kotlin.incremental=false
```

### 手机端 DNS 解析失败

**现象**：App 报 `Failed host lookup: 'apihub.agnes-ai.cn' (OS Error: No address associated with hostname, errno = 7)`

**原因**：手机网络（运营商 DNS / 私人 DNS / 路由器）解析不了 Cloudflare 托管的域名。

**排查**：
1. 手机浏览器访问 `https://apihub.agnes-ai.com/v1`，看能不能打开
2. 打不开 → 改手机 DNS：Android「私人 DNS」设为 `dns.google` 或 `1.1.1.1`
3. 或切换网络（WiFi ↔ 4G）验证

## 隐私

- API Key 仅存本地，通过 HTTPS 直发 Agnes
- 生成的图片保存在应用文档目录，不主动上传任何服务器
- 无遥测、无统计、无第三方 SDK

## License

MIT

---

**PromptForge Lite** · v0.1.0