# Health Assistant · 健康助手

Health Assistant（健康助手）是一款面向久坐人群的 Flutter 应用，支持 Android 和 iOS。应用通过本地通知提醒用户起身拉伸、喝水和休息眼睛，也提供植物养成和体感小游戏，让短暂的休息时间多一种活动选择。

当前版本 **1.1.0**。

## 主要功能

- **健康提醒**：可设置久坐拉伸、喝水和护眼提醒，以及免打扰时段。可完成、稍后处理或关闭某类提醒。
- **拉伸指导**：提供分步骤的动作说明，可在拉伸页查看和练习。
- **健康标签与计步**：可编辑健康标签。计步使用手机传感器，Android 需要「身体活动」权限，iOS 需要「运动与健身」权限。
- **花园和小游戏**：可种植植物、收集阳光。接阳光和看星星通过前置摄像头识别头部动作，需要相机权限。

## 构建与运行

| 工具或平台 | 版本 |
| --- | --- |
| Flutter | 3.44.1（项目验证使用的版本） |
| Dart | `^3.12.0`（随 Flutter SDK 提供） |
| Melos | 8.10.1 |
| Android SDK | API 36（编译和目标版本），最低 API 26 |
| Gradle Wrapper | 9.1.0 |
| iOS | 最低 15.5，构建需要 macOS 和 Xcode |

首次构建需要联网。

在仓库根目录执行：

```sh
dart pub global activate melos 8.10.1
melos bootstrap
melos run gen
cd app
```

按目标平台选择命令：

| 平台 | 构建 | 运行 |
| --- | --- | --- |
| Android | `flutter build apk --debug --flavor dev` | `flutter run --flavor dev` |
| iOS | `flutter build ios --simulator` | `flutter run` |

## 代码结构

| 目录 | 职责 |
| --- | --- |
| `app/` | 应用入口、导航、依赖组装和 Android/iOS 工程 |
| `feature_*/` | 页面、交互及共享 UI 组件 |
| `domain_all/` | 业务用例 |
| `core_*/` | 数据模型、存储、提醒和健康数据接入 |
| `base_*/` | 基础工具及静态分析规则 |

## 版权与许可

Copyright © 2026 Colin994

项目代码采用 [MIT 许可证](LICENSE)。游戏美术资源保留所有权利，第三方依赖适用各自的许可条款。
